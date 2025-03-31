// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
修正後程式碼說明：
修正了呼叫函式時傳遞參數的錯誤順序問題，
現在的 guess() 函式正確地以 (獎金, 猜測數字, 使用者) 的順序呼叫 checkAndTransferPrize()，
只有當使用者傳入正確數字，即與 _secretNumber 相符時才會轉移獎金。

測試步驟：
1. 部署修正後的 GuessTheNumber 合約並設定秘密數字 _secretNumber。
2. 攻擊者試圖以錯誤數字呼叫 guess()，由於參數正確，僅能在提供正確 _secretNumber 時獲獎金，否則僅觸發錯誤事件。
*/

contract GuessTheNumber {
    uint private _secretNumber; // 由部署者設定的秘密數字
    event success(string message);
    event wrongNumber(string message);

    // 建構子設定秘密數字
    constructor(uint secretNumber) {
        _secretNumber = secretNumber;
    }

    // 定義正確接收 Ether 的函式
    receive() external payable {}

    // 修正後的 guess() 函式，正確傳遞參數順序
    function guess(uint n) payable public {
        require(msg.value == 1 ether, "Require exactly 1 ether");
        uint p = address(this).balance;
        // 正確使用參數順序：(獎金, 猜測數字, 使用者)
        checkAndTransferPrize(p, n, payable(msg.sender));
    }

    // 內部函式檢查數字，若正確則轉移全部獎金
    function checkAndTransferPrize(uint p, uint n, address payable guesser) internal returns(bool) {
        if(n == _secretNumber) {
            guesser.transfer(p);
            emit success("You guessed the correct number!");
            return true;
        } else {
            emit wrongNumber("Youve made an incorrect guess!");
            return false;
        }
    }
}

// 修正後的攻擊合約範例：試圖攻擊修正後的合約，但由於漏洞已修復，攻擊不會成功。
contract AttackFixed {
    GuessTheNumber public target;
    event AttackResult(bool success);

    /*
    注意：
    為了解決之前的編譯錯誤，此處建構子參數改為 address payable。
    */
    constructor(address payable _target) {
        target = GuessTheNumber(_target);
    }

    /*
    攻擊步驟說明：
    1. 攻擊者呼叫 attack() 並傳送 1 ether。
    2. 由於參數傳遞正確，只有當使用者正確傳入 _secretNumber 時獎金才會被轉移。
    3. 若攻擊者未提供正確數字，僅會觸發 wrongNumber 事件而不會轉移 Ether。
    */
    function attack() external payable {
        require(msg.value == 1 ether, "Need to send 1 ether for the attack");
        // 攻擊者傳入未經正確猜測的數值，將無法獲得獎金
        target.guess{value: 1 ether}(123);
        emit AttackResult(true);
    }

    // 使本合約能接收從目標合約轉入的 Ether
    receive() external payable {}
}
