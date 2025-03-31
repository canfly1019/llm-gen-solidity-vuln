pragma solidity >=0.8.0;

// 修正說明：
// 為了避免 Conversion Bugs 漏洞，我們在從 uint256 轉換為 uint8 前，先檢查輸入數值是否在 uint8 的有效範圍內（0~255）。
// 如果輸入超出範圍則拒絕操作，避免後續的截斷

contract SafeConversion {
    // 狀態變數仍然使用 uint8，但轉換前會確認數值正確
    uint8 public importantValue;

    // 修正後的函式 setImportantValue：在轉換之前，先檢查 _val 是否於 uint8 可接受的範圍內
    function setImportantValue(uint256 _val) public {
        require(_val <= type(uint8).max, "Input value out of range");
        importantValue = uint8(_val);
    }

    // 檢查函式：與漏洞版本相似
    function checkValue(uint256 _input) public view returns (bool) {
        return (_input == importantValue);
    }
}

/*
修正後的測試步驟：
1. 部署 SafeConversion 合約。
2. 當呼叫 setImportantValue(256) 時，require 將會失敗，拒絕輸入不合法的數值。
3. 僅允許合法範圍內（0~255）的輸入，確保轉換不會導致截斷錯誤。
*/
