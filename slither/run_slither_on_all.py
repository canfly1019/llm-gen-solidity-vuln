import os
import subprocess
import re

SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src'))
OUTPUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), 'output'))
SLITHER_CMD = 'slither'

def ensure_output_dir():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

def run_slither_on_file(filepath):
    filename = os.path.basename(filepath)
    name_without_ext = os.path.splitext(filename)[0]
    output_txt = os.path.join(OUTPUT_DIR, f"{name_without_ext}.slither.txt")

    print(f"🔍 Analyzing {filename} ...")

    try:
        result = subprocess.run(
            [SLITHER_CMD, filepath],
            capture_output=True,
            text=True,
            check=False
        )

        full_output = result.stdout
        if result.stderr:
            full_output += "\n=== STDERR ===\n" + result.stderr

        # 儲存輸出結果
        with open(output_txt, "w", encoding="utf-8") as f:
            f.write(full_output)

        # 從最後的 summary 抓 "X result(s) found"
        match = re.search(r'(\d+)\s+result\(s\)\s+found', full_output)
        if match:
            issue_count = int(match.group(1))
        else:
            issue_count = 0

        return name_without_ext, issue_count

    except Exception as e:
        print(f"❌ Failed on {filename}: {e}")
        return filename, -1

def main():
    ensure_output_dir()
    summary = []

    for root, _, files in os.walk(SRC_DIR):
        for file in sorted(files):
            if file.endswith(".sol"):
                filepath = os.path.join(root, file)
                contract_name, count = run_slither_on_file(filepath)
                if count >= 0:
                    summary.append(f"[✓] {contract_name}: {count} issue(s)")
                else:
                    summary.append(f"[✗] {contract_name}: ❌ Analysis failed")

    # 輸出 summary.txt
    summary_path = os.path.join(OUTPUT_DIR, "summary.txt")
    with open(summary_path, "w", encoding="utf-8") as f:
        f.write("\n".join(summary))

    print("\n📄 Summary saved to:", summary_path)
    print("\n".join(summary))

if __name__ == "__main__":
    main()
