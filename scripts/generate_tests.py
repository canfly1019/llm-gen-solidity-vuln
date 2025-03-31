import os
import pandas as pd
from dotenv import load_dotenv
from pydantic import BaseModel
from bs4 import BeautifulSoup
from openai import OpenAI
from common import clean_code, write_file

# 讀取 .xlsx
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

# 結構化 GPT 請求與輸出
def generate_tests(file: str, error_message: str = None):
    # 判斷是 Fixed 合約還是 Vulnerable 合約
    label = "Vulnerability" if "vulnerability" in file else "Fixed"
    # 擷取 prefix 作為索引 (例如 1.1.1)
    base_name = file.replace("-vulnerability.sol", "").replace("-fixed.sol", "")
    index = base_name.split("-")[0]
    # 根據 index 取得 description
    vuln_description = desc_map.get(index, "")

    # 讀取原始合約內容並清理前後空白
    with open(os.path.join(src_dir, file), "r", encoding="utf-8") as f:
        content = clean_code(f.read())
    print(f"Generating test for: {file} via GPT...")

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

    # 組合 messages 發送給 GPT (包含漏洞描述與合約內容)
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": f"""Filename: {file}

        Target Solidity version: ^0.8.0

        You MUST ensure the generated test uses `pragma solidity ^0.8.0;` at the top.
        Do NOT use ^0.8.13, ^0.8.17, or any other version.
         
        Please focus the tests specifically on the vulnerability described below.
        You do NOT need to cover general functionalities or unrelated edge cases.

        If any reverts or failures are expected behavior (e.g., access control or safe checks), 
        you MUST explicitly handle them using `vm.expectRevert`, `try/catch`, or assertions, 
        so that the test does not fail unexpectedly.
         
        Description of the vulnerability to guide your test writing:
        {vuln_description}

        Write a Forge Foundry test for the following Solidity contract using this version:

        {content}
        """}
    ]

    # 如果是因為前一次失敗才呼叫此函數，也要提供 error 給 GPT 參考。
    if error_message:
        messages.append({
            "role": "user",
            "content": f"The previously generated test failed to compile. Here is the error message:\n\n{error_message}\n\nPlease regenerate a corrected and working test."
        })

    # 處理 GPT 回傳的結果
    try:
        response = client.beta.chat.completions.parse(
            model="o3-mini-2025-01-31",
            messages=messages,
            response_format=FoundryTestOutput,
        )
        test_code = response.choices[0].message.parsed.test_code
    except Exception as e:
        print(f"GPT generation failed:\n\n{e}\n")
        print(f"Skipping test generation for {file}")
        return

    # 寫入 test 檔案
    test_file_path = os.path.join(test_dir, f"{base_name}-{label.lower()}.t.sol")
    write_file(test_file_path, test_code)
    print(f"Generated: {test_file_path}")
