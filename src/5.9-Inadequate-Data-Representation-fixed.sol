pragma solidity >=0.8.0;
// SPDX-License-Identifier: UNLICENSED

/*
  修正後：正確使用 Solidity 原生單位表示信用額度
  將 credit 正確表達為 1 ether，避免因為手寫大數字所導致的審計風險。

  在這個修正版本中，當用戶存入 1 ether 並呼叫 withdraw 函數時，
  只會轉出正確的 1 ether，不會出現額外資金流失的問題。
*/

contract MyContract {
    // 修正重點：採用原生的 1 ether 表示，清楚且易讀
    uint public credit = 1 ether;

    function deposit() public payable {
        require(msg.value == 1 ether, "Deposit 1 ether exactly");
    }

    // withdraw 函數：將正確的 1 ether 轉給呼叫者
    function withdraw() public {
        payable(msg.sender).transfer(credit);
    }

    receive() external payable {}
}

// 模擬攻擊合約：儘管攻擊者仍嘗試以相同流程操作，但由於 credit 數值已正確，
// 最終僅能提取正確額度的 1 ether，不會造成資金流失
contract Attack {
    MyContract public fixedContract;

    constructor(address _fixedContract) {
        fixedContract = MyContract(payable(_fixedContract));
    }

    function attack() external payable {
        require(msg.value == 1 ether, "Send exactly 1 ether to attack");
        fixedContract.deposit{value: msg.value}();
        fixedContract.withdraw();
    }

    receive() external payable {}
}
