import os
import subprocess
from datetime import datetime
from generate_tests import generate_tests

MAX_ATTEMPTS = 5
src_dir = "src"
test_dir = "test"
log_dir = "scripts"
log_file_path = os.path.join(log_dir, "logs.txt")
os.makedirs(log_dir, exist_ok=True)

# 所有要測試的 solidity 檔案名稱
sol_files = sorted([
    f for f in os.listdir(src_dir)
    if f.endswith("-vulnerability.sol") or f.endswith("-fixed.sol")
])

# 根據原始合約檔案命名出對應的測試檔名
def get_test_filename(src_filename: str) -> str:
    base_name = src_filename.replace("-vulnerability.sol", "").replace("-fixed.sol", "")
    suffix = "vulnerability" if "vulnerability" in src_filename else "fixed"
    return f"{base_name}-{suffix}.t.sol"

# 寫 log 用的 function
def append_log(text: str):
    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(text + "\n")

# 開始紀錄
append_log(f"\n===== Test run started: {datetime.now()} =====\n")

start_from = "6.1.3"  # 控制從哪個 index 開始
end_at = "8.1.1"  # 控制在哪個 index 結束，設為空字串或 None 代表執行到最後
skip = True
finished = False

for src_file in sol_files:
    # 獲取當前文件的 index
    current_index = src_file.split("-")[0]
    
    # 檢查是否超過結束點 (若 end_at 為空則不檢查)
    if end_at and current_index > end_at:
        log = f"Reached ending index: {end_at}, stopping processing"
        print(log)
        append_log(log)
        finished = True
        break
        
    if skip:
        if src_file.startswith(start_from):
            skip = False # 找到起點後開始處理
            log = f"Starting processing from index: {start_from}"
            print(log)
            append_log(log)
        else:
            continue
    test_file = get_test_filename(src_file)
    test_path = os.path.join(test_dir, test_file)

    if os.path.exists(test_path):
        continue

    for attempt in range(1, MAX_ATTEMPTS + 1):
        # 檢測 .t.sol 是否存在，不在的話先生成
        if not os.path.exists(test_path):
            log = f"Test file not found, generating first: {test_file}"
            print(log)
            append_log(log)
            generate_tests(src_file)

        # 跑 forge test match file 指令
        log = f"\nRunning forge test: {test_file} (attempt {attempt})"
        print(log)
        append_log(log)
        result = subprocess.run(
            ["forge", "test", "--match-path", f"test/{test_file}", "-vvvv"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )

        ## 根據指令運行結果紀錄
        if result.returncode == 0:
            log = f"Passed: {test_file}"
            print(log)
            append_log(log)
            break
        else:
            log = f"Failed: {test_file}"
            print(log)
            append_log(log)

            error_output = result.stdout.strip()
            append_log("Error:\n" + error_output)
            print("Error:\n" + error_output)

            # 回傳 error 重新生成 .t.sol
            log = f"Regenerating: {test_file}"
            print(log)
            append_log(log)
            generate_tests(src_file, error_message=error_output)

    # for-else 語法，沒有 break for 代表 attempt 五次的話才執行。
    else:
        log = f"Failed after {MAX_ATTEMPTS} attempts: {test_file}"
        print(log)
        append_log(log)

        # Delete bad test file
        if os.path.exists(test_path):
            os.remove(test_path)
            log = f"Deleted test file due to repeated failure: {test_file}"
            print(log)
            append_log(log)
        continue

# 結束紀錄
append_log(f"\n===== Test run finished: {datetime.now()} =====\n")
