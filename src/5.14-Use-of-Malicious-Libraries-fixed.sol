pragma solidity >=0.8.0;

// SPDX-License-Identifier: UNLICENSED

// 修正說明：
// 此範例修正了漏洞，改用信賴的第三方庫，確保函式計算回傳正確數值，避免因惡意庫所導致的數值操控。

// 模擬安全庫 (Safe Library)
library SafeLibrary {
    // 修復重點：此處的 doSomething 函式將正確返回輸入值，不作任何惡意數值放大或操縱
    function doSomething(uint x) external pure returns (uint) {
        return x; // 正常行為：如實返回輸入數值
    }
}

// 修正後的合約：使用了安全庫進行計算
contract ExampleLibrary {
    uint public data; // 狀態變數保持原用意

    // 修正漏洞：使用可信賴的 SafeLibrary 執行計算，避免惡意操控
    function updateData(uint _data) public {
        data = SafeLibrary.doSomething(_data); // 使用安全庫進行操作
    }

    // 定義 fallback 與 receive 函式以正確接收 Ether
    receive() external payable {}
    fallback() external payable {}
}

// 攻擊示例合約：在此情境下，即使攻擊者嘗試呼叫 updateData，由於計算安全，
// victim.data 將準確地保持輸入值，不會被惡意庫放大。
// 修改處：將 constructor 參數型別更改為 address payable，解決顯式轉換錯誤
contract AttackExample {
    ExampleLibrary public victim;

    constructor(address payable _victim) {
         victim = ExampleLibrary(_victim);
    }

    function attack() public {
         victim.updateData(10);
         // 此時 victim.data 應正確顯示 10，攻擊失敗，漏洞已被修復
    }
}
