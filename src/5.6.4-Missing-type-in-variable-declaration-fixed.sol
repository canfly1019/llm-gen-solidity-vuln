// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
修正說明：
為了修正數值運算可能因型態不當而導致的 overflow/underflow 風險，
我們明確宣告迴圈變數及運算變數為 unsigned integer (uint256)。
這樣可以確保不會因出現負數而誤判或是產生額外的 gas 費用。

部署與測試步驟：
1. 部署 FixedContract 合約。
2. 呼叫 attack() 函式，應正確返回 0+1+2+...+256 的加總結果，不存在數學邏輯風險。
*/

contract FixedContract {
    function calculateSum() public pure returns (uint256) {
        uint256 sum = 0;
        // 明確使用 uint256 來宣告迴圈變數
        for (uint256 i = 0; i <= 256; i++) {
            // 在本例中 0~256 加總不會溢出，但使用正確型態能避免潛在風險
            unchecked {
                sum += i;
            }
        }
        return sum;
    }

    function attack() external pure returns (uint256) {
        return calculateSum();
    }
}
