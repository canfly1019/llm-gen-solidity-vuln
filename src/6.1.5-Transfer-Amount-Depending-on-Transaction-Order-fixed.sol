/*
 SPDX-License-Identifier: MIT

 此修正版本旨在防範 Transfer Amount Depending on Transaction Order 的漏洞，
 引入了一個 order 變數來記錄操作順序，只有在接收者操作 (order == 2) 之後，
 才能執行轉帳。
 編譯錯誤解決：AttackFixed 的 constructor 參數型別改為 address payable。
*/
pragma solidity >=0.8.0;

// 修正後的合約，加入 order 變數控制操作順序，避免交易排序影響 amount 的值
contract AmountSenderFixed {
    uint public amount = 1;
    uint public order = 0;  // 記錄最後一次操作來源：1 表示供應者，2 表示接收者

    // 供應者操作，設定 order 為 1
    function setAmountOp2(uint _amount) public {
        order = 1;
        if (isProvider(msg.sender)) {
            amount = _amount;
        }
    }

    // 接收者操作，設定 order 為 2
    function setAmountOp1(uint _amount) public {
        order = 2;
        if (isRecipient(msg.sender)) {
            amount = _amount;
        }
    }

    // 簡化的供應者驗證，實際使用時會有更嚴格的檢查
    function isProvider(address sender) public pure returns (bool) {
        return true;
    }

    // 簡化的接收者驗證
    function isRecipient(address sender) public pure returns (bool) {
        return true;
    }

    // 修正後的轉帳函式，在執行轉帳前確認 order 為 2，確保是接收者的動作
    function setTransferAmount() public {
        require(isRecipient(msg.sender), "Not recipient");
        require(order == 2, "Operation order error");

        payable(msg.sender).transfer(amount);
    }

    // 必須的接收 Ether 函式
    receive() external payable {}
}

// 攻擊合約，企圖重現原漏洞版本的攻擊流程
contract AttackFixed {
    AmountSenderFixed public target;

    // 修改 constructor 參數型別為 address payable 以避免類型轉換錯誤
    constructor(address payable _target) {
        target = AmountSenderFixed(_target);
    }

    // executeAttack 示範攻擊流程：
    // 1. 先以供應者角色呼叫 setAmountOp2 設定高額 (例如 1000)
    // 2. 再以接收者角色呼叫 setAmountOp1 設定小額 (例如 1)，更新 order 為 2
    // 3. 若交易順序正確，setTransferAmount 就會執行；否則 require 檢查失敗，轉帳不會執行
    function executeAttack() public {
        target.setAmountOp2(1000);
        target.setAmountOp1(1);
        target.setTransferAmount();
    }

    // 允許合約接收 Ether
    receive() external payable {}
}
