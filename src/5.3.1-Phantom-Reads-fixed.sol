// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
  修正說明：
  為避免 phantom reads 的問題，修正後的合約將資料讀取與運算整合在同一個原子性函式中，
  不再依賴外部輸入的快照數據，從而確保整個運算過程中所使用的資料是一致且最新的。
  此方式可有效避免在處理過程中因資料變更而導致的錯誤運算結果。
*/

contract FixedPhantom {
    // 狀態變數：紀錄陣列
    uint256[] public records;

    // 允許任何人新增紀錄
    function addRecord(uint256 value) public {
        records.push(value);
    }

    // 修正後的處理函式：在單一原子性交易內完成資料讀取與運算，避免中間狀態變更
    function processRecords() public view returns (uint256 sum) {
        uint256 length = records.length;
        for (uint256 i = 0; i < length; i++) {
            sum += records[i];
        }
        return sum;
    }
}

/*
  攻擊範例說明：
  由於修正後的 processRecords() 函式在單一交易內完成所有動作，
  即便同一區塊中有其他交易改變 records 狀態，由於區塊內交易的原子性，
  此運算仍會使用一致的資料，不會發生 phantom reads 的問題。
  因此，攻擊者無法再利用快照數據與最新狀態之間的差異進行攻擊。
*/
