// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
漏洞修正策略：
  為了修正 Isolation Phenomena 漏洞，我們應該避免在查詢運算中使用容易變動的區塊參數（例如 block.timestamp）。
  修正方式是在合約部署或關鍵時刻固定那些參數，並存入不再變化的 state 變數中。
  這樣即使在不同區塊中查詢，也能獲得一致的結果，避免攻擊者藉時機選擇獲取較大利益。
*/

contract IsolationFixed {
    uint public constant baseReward = 100;
    // 修正重點：在建構子中固定 Bonus 值，一旦設定後，在後續查詢中保持不變
    uint public immutable fixedBonus;

    constructor() {
        // 在合約部署時將 Bonus 固定
        fixedBonus = block.timestamp % 10;
    }

    // 修正後的查詢函數，可保證查詢結果在合約生命週期內保持一致
    function getReward() public view returns (uint) {
        return baseReward + fixedBonus;
    }
}

// 攻擊者原本可能利用 getReward 的不一致性製造套利，但現在 getReward 固定返回相同的值，
// 攻擊者無法再藉此取得額外利益。
// 若要測試，部署 IsolationFixed 合約並呼叫 getReward，多次查詢應返回相同數值。
