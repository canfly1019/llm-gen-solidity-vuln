// Fixed Code
// 解決方案：避免使用 delegatecall 呼叫未信任的外部 library，或者將外部 library 改寫為內部 library（使用 internal 語意編譯進主合約）。
// 此範例改用 Solidity 內部 library，從而將外部依賴問題消除，防止被惡意修改狀態變數。

pragma solidity >=0.8.0;

// 使用 Solidity 內部庫的寫法
library SafeLibrary {
    // 此函式僅為純計算，無存儲修改，避免 delegatecall 帶來的安全風險
    function doSomething(uint256 _val) internal pure returns (uint256) {
        // 範例邏輯：將數值乘以 2
        return _val * 2;
    }
}

contract FixedContract {
    address public owner;
    uint256 public someValue;
    
    // 初始化設定 owner 為部署者
    constructor() {
        owner = msg.sender;
    }
    
    // 執行函式直接使用內部庫呼叫，不依賴外部 delegatecall
    // 攻擊者無法透過外部合約覆寫邏輯
    function execute(uint256 _val) public {
        someValue = SafeLibrary.doSomething(_val);
    }
    
    // 接收 Ether 的 fallback 函式
    receive() external payable {}
}

/*
修正後的部署與操作說明：
1. FixedContract 不再依賴外部 library 透過 delegatecall 進行邏輯處理，而是使用內部連結 (internal linkage) 的 SafeLibrary。
2. 因為 SafeLibrary 是內部呼叫，不涉及外部合約，攻擊者無法利用外部惡意合約來改變 FixedContract 儲存狀態。
*/
