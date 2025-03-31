// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
   修正說明:
   已修正 Typographical Error 漏洞，將 alwaysOne() 函式中的運算操作由錯誤的賦值修正為累加操作。
   現在每次呼叫 alwaysOne() 時，numberOne 都會正確累加 1。

   攻擊示範:
   若攻擊者或使用者重複呼叫 alwaysOne()，則查詢 numberOne 時將發現其值正確累加，例如初始值為 1，呼叫 5 次後會變為 6。
*/

contract TypoOneCommandFixed {
    // 狀態變數
    uint public numberOne = 1;

    // 修正後的函式：使用 '+=' 運算子正確進行累加
    function alwaysOne() public {
        numberOne += 1;
    }
}

// 測試合約，用以驗證修正後功能正確
contract TestTypoFixed {
    TypoOneCommandFixed public target;

    // 部署時需提供目標合約地址
    constructor(address _targetAddress) {
        target = TypoOneCommandFixed(_targetAddress);
    }

    // 模擬多次呼叫 alwaysOne() 進行累加
    function testIncrement() public {
        for (uint i = 0; i < 5; i++) {
            target.alwaysOne();
        }
    }

    // 查詢 numberOne 的當前數值
    function getNumber() public view returns (uint) {
        return target.numberOne();
    }
}
