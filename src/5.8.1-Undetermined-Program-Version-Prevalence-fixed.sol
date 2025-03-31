// SPDX-License-Identifier: MIT
// 修正說明：透過鎖定確切的 compiler 版本，強制所有使用者及部署者必須使用相同編譯器版本，避免因編譯器版本改變導致行為不一致的問題。
// 這裡我們將 compiler 版本鎖定為 0.8.0，確保部署環境與開發環境一致。

pragma solidity 0.8.0;

contract PragmaFixed {
    // 修正重點：明確指定編譯器版本 0.8.0，避免未來版本引入新增行為或漏洞
    uint public x = 1;
}

// 攻擊合約示範 (模擬攻擊)：
// 雖然我們提供了攻擊合約示範，但由於 PragmaFixed 合約已鎖定至 0.8.0，攻擊者無法透過改變編譯器版本來觸發意外行為

contract AttackFixed {
    PragmaFixed public fixedTarget;

    // 部署 AttackFixed 前需先部署 PragmaFixed 合約，並將其地址提供給此合約
    constructor(address _fixedTarget) {
        fixedTarget = PragmaFixed(_fixedTarget);
    }

    // 呼叫 callGetX() 以確保合約行為始終與預期一致
    function callGetX() public view returns (uint) {
        return fixedTarget.x();
    }
}

/*
測試/部署流程說明 (繁體中文)：
1. 請使用 Solidity 0.8.0 編譯並部署此合約，避免使用其他版本。
2. 部署 PragmaFixed 合約後，再部署 AttackFixed 合約並傳入 PragmaFixed 合約的地址。
3. 呼叫 callGetX() 函式，確認始終回傳數值 1，確保已消除因編譯器版本不確定性導致的行為異常。
*/