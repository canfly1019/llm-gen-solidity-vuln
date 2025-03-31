// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// 修正後的合約，使用無符號整數 (uint) 作為提款金額，避免 Signedness Bugs

contract FixedWithdraw {
    mapping(address => bool) public transferred; // 記錄是否已提款

    // 修正後的 withdrawOnce 函數，amount 為 uint 型別，無法傳入負數
    function withdrawOnce(uint amount) public {
        // 驗證：提款金額必須不超過 1 ether，且使用者未曾提款
        require(amount <= 1 ether, "Amount exceeds limit");
        require(!transferred[msg.sender], "Already withdrawn");
        payable(msg.sender).transfer(amount);
        transferred[msg.sender] = true;
    }

    // 接收 Ether
    receive() external payable {}
}

// 攻擊合約示例：試圖使用攻擊合約提款，但由於正確使用 uint，僅能獲得合法金額

contract AttackFixed {
    FixedWithdraw public fixedContract;

    // 建構子使用 address payable 型別傳入 FixedWithdraw 地址
    constructor(address payable _fixedAddress) {
        fixedContract = FixedWithdraw(_fixedAddress);
    }

    // 嘗試提領 0.5 ether，這在正確的合約邏輯下只會提款合法金額
    function attack() public {
        fixedContract.withdrawOnce(0.5 ether);
    }

    // 接收 Ether
    receive() external payable {}
}

/*
修正後的運作流程：
1. 部署 FixedWithdraw 合約，並注入足夠的 Ether。
2. 部署 AttackFixed 合約，傳入 FixedWithdraw 的 payable 地址。
3. 呼叫 AttackFixed 的 attack() 函數，僅能提領 0.5 ether（或其他在限額內的金額）。
   修正後的合約因使用 uint 型別，無法傳入負數，從而避免了 Signedness Bugs 問題。
*/
