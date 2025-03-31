pragma solidity >=0.8.0;
// SPDX-License-Identifier: UNLICENSED

// FixedContract 合約透過建構式參數來指定受益者地址，避免硬編碼漏洞，增強安全性與彈性

contract FixedContract {
    // 修正重點：受益者 address 現在改為變數，並透過建構式傳入
    address payable public beneficiary;

    constructor(address payable _beneficiary) {
         require(_beneficiary != address(0), "Invalid address");
         beneficiary = _beneficiary;
    }

    // donate() 函式將收到的 Ether 轉發給部署時指定的 beneficiary
    function donate() external payable {
        require(msg.value > 0, "Must send some Ether");
        beneficiary.transfer(msg.value);
    }

    // fallback 函式，用來接收 Ether
    receive() external payable {}
}

/*
 使用範例說明（繁體中文）：
 部署 FixedContract 時，由部署者自行提供目標 beneficiary 地址，此地址不可更改，確保資金只流向正確的帳戶。
 若攻擊者嘗試利用類似攻擊方式，也無法將捐出的資金導到錯誤的帳戶。
*/

// 以下為示例之呼叫攻擊合約，僅用於互動示範
contract FixedAttacker {
    FixedContract public fixedContract;

    // 修改建構子，利用 payable 轉型，以解決編譯問題
    constructor(address _fixedContract) {
        fixedContract = FixedContract(payable(_fixedContract));
    }

    function attack() external payable {
        fixedContract.donate{value: msg.value}();
    }

    receive() external payable {}
}
