pragma solidity >=0.8.0;

// 修正後的合約展示如何正確標示函數類型 (Wrong Type of Function) 的問題
// 修正重點：將 getResult 函數類型從 view 修正為 pure，正確表達不讀取狀態變數

contract Test {
    // 修正：使用 pure，因為本函數僅進行純計算，無讀取或修改狀態變數
    function getResult() public pure returns (uint product, uint sum) {
        uint num1 = 2;
        uint num2 = 4;
        product = num1 * num2;
        sum = num1 + num2;
    }
}

// 測試合約：用以呼叫 Test 合約中的 getResult 函數，展示正確的函數定義

contract TestCaller {
    // 此函數呼叫 Test 合約的 getResult 並返回結果
    // 因為 getResult 被正確標示為 pure，所以不會誤導開發者，也確保了正確的 gas 計算
    function callGetResult(address testAddress) public pure returns (uint, uint) {
        return Test(testAddress).getResult();
    }
}

/* 部署與測試流程說明：
   1. 部署修正後的 Test 合約。
   2. 部署 TestCaller 合約，並以 Test 合約地址作為參數呼叫 callGetResult，
      取得正確的運算結果 (product 與 sum)。
   3. 此修正不僅符合 Solidity >=0.8.0 的語法，也避免了因錯誤文檔導致的潛在混淆。
*/