pragma solidity >=0.8.0;

/*
修正後程式碼：
本合約修正方式是，在讀取 buffer 陣列的資料前，檢查傳入的索引是否在合法範圍內，避免讀取任意的 storage。

攻擊手法防範：修正後的 readAt 函式只允許合法索引範圍(0-2)的存取，不再接受負數或超出界限的數值。
部署與測試流程：
1. 部署 Fixed 合約。
2. 呼叫 readAt(0)、readAt(1) 或 readAt(2) 均能正確讀取 buffer；若呼叫 readAt(3) 或其他非法值則 revert。
*/

contract Fixed {
    // 安全的 state variable 設定，buffer 陣列僅包含合法的三個元素 (slot 0,1,2)
    bytes32[3] public buffer;
    uint256 public secret;  // secret 存在 slot 3，但不會因為 bounds check 而外洩

    constructor() {
        // 初始化 buffer 陣列
        buffer[0] = keccak256(abi.encodePacked("A"));
        buffer[1] = keccak256(abi.encodePacked("B"));
        buffer[2] = keccak256(abi.encodePacked("C"));
        secret = 999;
    }

    // 修正的函式：僅提供合法範圍的存取，並利用 solidity 的內建索引機制，避免任意 storage 存取
    function readAt(uint256 index) public view returns (bytes32) {
        require(index < buffer.length, "index out of bound");
        return buffer[index];
    }
}

/*
攻擊範例說明：
- 部署合約後，呼叫 readAt(0), readAt(1), readAt(2) 將合法回傳 buffer 的內容；
- 呼叫 readAt(3) 或其他超出範圍的索引將因 require 檢查失敗而 revert，因此無法利用漏洞讀取 secret 等其它資料。
*/
