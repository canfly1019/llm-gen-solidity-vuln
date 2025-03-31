pragma solidity >=0.8.0;
// SPDX-License-Identifier: UNLICENSED

/*
    修正後程式碼：
    說明：在部署合約時的 constructor 中正確初始化 destination，避免預設值為 address(0) 的漏洞。
*/

contract Uninitialized {
    // 將 destination 宣告為 payable 並在 constructor 中初始化為部署者地址
    address payable public destination;

    constructor() {
        destination = payable(msg.sender);
    }

    // transfer() 函式：收到的 Ether 轉移至正確初始化後的 destination
    function transfer() public payable {
        destination.transfer(msg.value);
    }

    // 接收 Ether 的 fallback 函式
    receive() external payable {}
}

// 攻擊合約：此合約僅作為範例，呼叫 transfer() 後 Ether 會轉移到正確的 destination
contract Attack {
    Uninitialized public target;

    // 為解決編譯錯誤，將 _target 參數型態修改為 address payable
    constructor(address payable _target) {
        target = Uninitialized(_target);
    }

    function attack() external payable {
        target.transfer{value: msg.value}();
    }
}

/*
    前置動作說明：
    1. 部署修正後的 Uninitialized 合約，其 constructor 將 destination 初始化為部署者地址。
    2. 部署 Attack 合約並傳入修正後合約的 payable 地址。
    3. 從任意地址呼叫 Attack.attack() 並傳入 Ether，
       此時 transfer() 會將 Ether 正確地轉移到部署者地址，避免資金遺失的漏洞。
*/