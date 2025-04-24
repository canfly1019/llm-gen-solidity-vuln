import os
import pandas as pd
from dotenv import load_dotenv
from pydantic import BaseModel
from openai import OpenAI
from common import clean_code, write_file

# 讀取 output.xlsx
excel_df = pd.read_excel("output.xlsx")
desc_map = dict(zip(excel_df['index'].astype(str), excel_df['description']))

# 載入 .env 環境變數
load_dotenv()
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise EnvironmentError("OPENAI_API_KEY not found in environment.")

# 初始化 OpenAI client
client = OpenAI(api_key=api_key)

# 定義 GPT 回傳格式
class FoundryTestOutput(BaseModel):
    test_code: str

# 路徑設置
src_dir = "src"
test_dir = "test"
os.makedirs(test_dir, exist_ok=True)

# 全局Session儲存LLM對話歷史
class Session:
    def __init__(self):
        self.sessions = {}
        
    def get_messages(self, key):
        if key not in self.sessions:
            self.sessions[key] = []
        return self.sessions[key]
    
    def add_message(self, key, role, content):
        if key not in self.sessions:
            self.sessions[key] = []
        self.sessions[key].append({"role": role, "content": content})
    
    def clear_session(self, key):
        if key in self.sessions:
            del self.sessions[key]

# 初始化全局對話管理器
session_manager = Session()

# 結構化 GPT 請求與輸出
def generate_tests(file: str, error_message: str = None, attempt: int = 1, reset_session: bool = False):
    # 判斷是 Fixed 合約還是 Vulnerable 合約
    label = "Vulnerability" if "vulnerability" in file else "Fixed"
    # 擷取 prefix 作為索引 (例如 1.1.1)
    base_name = file.replace("-vulnerability.sol", "").replace("-fixed.sol", "")
    index = base_name.split("-")[0]
    # 使用檔案名作為session的key
    session_key = f"{base_name}-{label.lower()}"
    
    # 如果要重置對話歷史
    if reset_session:
        session_manager.clear_session(session_key)
    
    # 根據 index 取得 description
    vuln_description = desc_map.get(index, "")

    # 讀取原始合約內容並清理前後空白
    with open(os.path.join(src_dir, file), "r", encoding="utf-8") as f:
        content = clean_code(f.read())
    print(f"Generating test for: {file} via GPT... (attempt {attempt})")
    
    # 獲取當前session的對話歷史
    messages = session_manager.get_messages(session_key)
    
    # 如果是第一次對話，初始化對話歷史
    if not messages:
        # 根據 label 決定 system prompt
        if label == "Fixed":
            system_prompt = (
                "You are a Solidity security auditor. The following contract is a FIXED version, "
                "meaning the vulnerability has been resolved. Do NOT expect reverts or failed attacks. "
                "Write tests that confirm the contract behaves securely and correctly."
            )
        else:
            system_prompt = (
                "You are a Solidity security auditor. The following contract is a VULNERABLE version. "
                "Demonstrate the issue using tests. You may expect reverts and include exploit logic."
            )
            
        # 添加系統訊息
        session_manager.add_message(session_key, "system", system_prompt)
        
        # 添加初始用戶訊息
        initial_user_message = f"""Filename: {file}

        Target Solidity version: ^0.8.0

        You MUST ensure the generated test uses `pragma solidity ^0.8.0;` at the top.
        Do NOT use ^0.8.13, ^0.8.17, or any other version.

        All test files are located in the `test/` directory.
        All contracts are located in the `src/` directory.
        Therefore, when importing the contract into the test, use relative paths like:
        `import "../src/{file}";`

        Please focus the tests specifically on the vulnerability described below.
        You do NOT need to cover general functionalities or unrelated edge cases.

        If any reverts or failures are expected behavior (e.g., access control or safe checks), 
        you MUST explicitly handle them using `vm.expectRevert`, `try/catch`, or assertions, 
        so that the test does not fail unexpectedly.

        Description of the vulnerability to guide your test writing:
        {vuln_description}

        Write a Foundry test for the following Solidity contract using this version:

        {content}
        """
        session_manager.add_message(session_key, "user", initial_user_message)
    
    # 如果有錯誤訊息，添加到對話歷史
    if error_message:
        error_user_message = f"""The previously generated test `{base_name}-{label.lower()}.t.sol` failed to compile (attempt {attempt-1}). 
        Here is the error message:

        {error_message}

        Please regenerate a corrected and working test based on the entire conversation history so far."""
        session_manager.add_message(session_key, "user", error_user_message)

    # 獲取更新後的對話歷史
    messages = session_manager.get_messages(session_key)
    
    # 處理 GPT 回傳的結果
    try:
        response = client.beta.chat.completions.parse(
            model="o4-mini-2025-04-16",
            messages=messages,
            response_format=FoundryTestOutput,
        )
        test_code = response.choices[0].message.parsed.test_code
        
        # 將LLM的回應添加到對話歷史
        session_manager.add_message(session_key, "assistant", response.choices[0].message.content)
    except Exception as e:
        print(f"GPT generation failed:\n\n{e}\n")
        print(f"Skipping test generation for {file}")
        return

    # 寫入 test 檔案
    test_file_path = os.path.join(test_dir, f"{base_name}-{label.lower()}.t.sol")
    write_file(test_file_path, test_code)
    print(f"Generated: {test_file_path}")
    
    return test_code
