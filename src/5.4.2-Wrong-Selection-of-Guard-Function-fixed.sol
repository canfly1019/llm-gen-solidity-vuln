// Solidity Version >=0.8.0
pragma solidity >=0.8.0;

// 修正後的合約：AssertMultiTx1
// 修正重點：在建構子中使用 require 檢查輸入的 _param 是否大於 0，
// 確保合約一經部署後狀態變數 param 永遠滿足不為 0 的 invariant；
// 另外，不再提供 set() 函式，使得狀態變數不會被後續任意更改。

contract AssertMultiTx1 {
    // 狀態變數，確保 param 只會在部署時進行正確初始化
    uint256 private param;

    // 建構子：輸入必須大於 0，否則部署將會失敗
    constructor(uint256 _param) {
        require(_param > 0, "Input must be greater than zero");
        param = _param;
    }

    // 此函式僅用於驗證 invariant，並且標記為 view，避免狀態更改或額外 gas 消耗
    function run() public view {
        // assert 用於內部 invariant 檢查，正常情況下應不會失敗
        assert(param > 0);
    }
}

// 攻擊測試說明（非攻擊代碼）：
// 嘗試利用部署後的 AssertMultiTx1 合約進行攻擊將會失敗，因為:
// 1. 建構子 require 檢查阻擋了任何未滿足條件的部署。
// 2. 合約中沒有提供修改 param 的函式，因此 invariant 得以被保持。
