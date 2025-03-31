pragma solidity >=0.8.0;
// SPDX-License-Identifier: UNLICENSED

// 修正後的合約將移除不必要的參數與局部變數，來優化 gas 耗費及提升程式碼可讀性
contract UnusedVariablesFixed {
    int a = 1;

    // 修正：移除未使用之參數 y，僅保留必要參數
    function unusedArg(int x) public view returns (int z) {
        z = x + a;
    }

    // 此處保留 unusedReturn 的 n 參數，因其屬於另一 SWC 分類，不在本修正範疇內
    function unusedReturn(int x, int y) public pure returns (int m, int n, int o) {
        m = y - x;
        o = m / 2;
    }

    // 修正：移除未使用的局部變數 x，僅保留必要邏輯
    function neverAccessed(int test) public pure returns (int) {
        int z = 10;
        if (test > z) {
            return test - z;
        }
        return z;
    }

    // 修正：使用 tuple assignment 時不引入額外變數，並標記為 pure 以符合狀態
    function tupleAssignment(int p) public pure returns (int q, int r) {
        (q, , r) = unusedReturn(p, 2);
    }
}

// 攻擊者合約：模擬呼叫修正後合約，證明移除未使用變數能降低不必要的資源分配
contract AttackUnusedVariablesFixed {
    UnusedVariablesFixed public fixedInstance;

    // 部署時提供修正後合約地址
    constructor(address _fixed) {
        fixedInstance = UnusedVariablesFixed(_fixed);
    }

    // 攻擊函式：呼叫各個函式並回傳結果，確保修正後合約僅分配必要資源
    function attack() public view returns (int, int, int, int) {
        int res1 = fixedInstance.unusedArg(10);
        (int m, int n, int o) = fixedInstance.unusedReturn(5, 15);
        int res2 = fixedInstance.neverAccessed(20);
        (int q, int r) = fixedInstance.tupleAssignment(4);
        return (res1, m, res2, q + r + n + o);
    }
}

/*
補充說明：
1. 此修正版本移除所有不必要的變數，用以降低額外 gas 耗費以及潛在的攻擊面。
2. 攻擊者透過 attack() 函式呼叫各功能，觀察執行成本改善，證明修正成果。
3. 本修正僅針對未使用變數漏洞做處理，unusedReturn 中未使用的變數 n 因屬於其他分類而保留。
*/