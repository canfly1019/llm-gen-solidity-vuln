pragma solidity >=0.8.0;

// SPDX-License-Identifier: UNLICENSED

// 修正後的合約
// 修復方向：
// 1. 將函式 claimReward 限定只有 owner 可呼叫，從而避免任意攻擊者藉由呼叫順序錯誤竊取 reward。
// 2. 合併 reward 設定與轉帳動作，避免在未更新 reward 前發生錯誤交易。

contract EthTxOrderDependenceMinimal {
    address payable public owner;
    uint public reward;

    constructor() {
        owner = payable(msg.sender);
    }

    // 修正後的 claimReward：只有 owner 可呼叫，並在同一函式內設置 reward 與轉帳
    function claimReward(uint256 submission) public payable {
        require(submission > 10, "Submission must be > 10");
        require(msg.sender == owner, "Only owner can call claimReward");
        // 於同一交易中設定 reward 並轉帳給 owner，避免函式呼叫順序問題
        reward = msg.value;
        owner.transfer(reward);
    }

    // receive function 用以接收 Ether
    receive() external payable {}
}

// 攻擊合約範例: AttackExploitFixed
// 嘗試呼叫 claimReward 進行攻擊，但由於只有 owner 可呼叫，故攻擊會失敗。

contract AttackExploitFixed {
    // 同樣處理地址轉換問題
    EthTxOrderDependenceMinimal public fixedContract;

    constructor(address _fixedContract) {
        fixedContract = EthTxOrderDependenceMinimal(payable(_fixedContract));
    }

    function attack(uint256 submission) public payable {
        // 攻擊者非 owner，將無法通過 require 檢查，導致交易 revert
        fixedContract.claimReward{value: msg.value}(submission);
    }

    // receive 用以接收 Ether
    receive() external payable {}
}
