pragma solidity >=0.8.0;
// SPDX-License-Identifier: UNLICENSED

// 修正描述：透過在除法運算前將分子乘以 10 的 precision 次方來保留小數位，實現了類似定點小數的運算效果。

contract Divide {
    // 修正後的函式 calcul
    // 請注意：在使用此函式時，需要確認除數 b 不為 0
    function calcul(uint a, uint b, uint precision) public pure returns (uint) {
        require(b > 0, "Division by zero");
        // 將 a 乘以 10^precision，再進行除法，以保留計算過程中的小數位資訊
        uint result = a * (10 ** precision) / b;
        return result;
    }
}

// 測試合約示範修正後除法運算的正確結果
contract FixedAttacker {
    // 由於使用 new 關鍵字創建合約實例涉及狀態改變，因此此函式不再宣告為 pure
    function testCalculation() public returns (uint) {
        Divide d = new Divide();
        uint value = d.calcul(4, 5, 2);
        // 在 precision 為 2 時，4/5 應返回 80 (代表 0.80)
        require(value == 80, "Calculation error, fixed division not working as expected");
        return value;
    }
}

/*
部署與測試說明:
1. 部署合約 Divide，其 calcul 函式利用先乘以 10^precision 的方式修正了整數除法的缺陷。
2. 部署 FixedAttacker 合約，並呼叫 testCalculation() 來測試 4/5 在 precision 為 2 時是否正確返回 80，從而驗證修正邏輯的正確性。
*/
