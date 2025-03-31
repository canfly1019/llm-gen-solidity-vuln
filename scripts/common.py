#  清除輸入字串的前後空白字元/換行。
def clean_code(code: str) -> str:
    return code.strip()

#  將內容寫入指定的檔案，使用 UTF-8 編碼。
def write_file(path: str, content: str):
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
