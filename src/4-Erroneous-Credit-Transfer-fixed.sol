pragma solidity >=0.8.0;

// SPDX-License-Identifier: UNLICENSED
// 修正後的合約，正確處理信用轉移操作

contract FixedCredit {
    // 正確紀錄每個使用者的餘額
    mapping(address => uint256) public credits;
    
    // 存款函式，累計使用者信用
    function deposit() external payable {
        require(msg.value > 0, "msg.value must be > 0");
        credits[msg.sender] += msg.value;
    }

    // 提款函式：在轉帳前先扣除使用者信用，避免多次提款
    function withdraw(uint256 amount) external {
        require(credits[msg.sender] >= amount, "Insufficient credit");
        // 修正重點：先扣除信用，再進行轉帳
        credits[msg.sender] -= amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Transfer failed");
    }

    // fallback 與 receive 正確定義，以接收 Ether
    fallback() external payable {}
    receive() external payable {}
}

// 攻擊合約範例：嘗試與 FixedCredit 互動，驗證漏洞已被修正
contract AttackFixed {
    FixedCredit public fixedContract;

    // 傳入 FixedCredit 合約地址，並修正地址轉換問題
    constructor(address _fixedAddress) {
        fixedContract = FixedCredit(payable(_fixedAddress));
    }

    // 攻擊流程說明：
    // 1. 攻擊者透過 deposit 存入 1 Ether
    // 2. 攻擊者嘗試多次呼叫 withdraw 1 Ether，但因信用扣除正確，第二次 withdraw 將失敗
    function attack() external payable {
        require(msg.value >= 1 ether, "Need at least 1 Ether");
        fixedContract.deposit{value: 1 ether}();
        
        // 第一次提款成功
        fixedContract.withdraw(1 ether);
        
        // 嘗試第二次提款會失敗，因為信用已扣除
        // 若取消下面的註解，將會 revert
        // fixedContract.withdraw(1 ether);
    }

    // 接收 Ether
    receive() external payable {}
}
