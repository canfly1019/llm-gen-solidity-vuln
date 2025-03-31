// Fixed Code Example
// 修正說明：
// 為了改善 gas 消耗問題，將迴圈外先行讀取 data.length 並儲存在一個記憶體變數中，
// 這樣即可避免在每次迴圈中重複讀取 state 變數，從而降低不必要的 gas 消耗。

pragma solidity >=0.8.0;

contract FixedContract {
    // 狀態變數：儲存需要處理的資料
    uint[] public data; // (修正重點) 資料儲存

    // 新增資料到 state 陣列中
    function addData(uint _value) public {
        data.push(_value);
    }

    // 改善後的計算總和函式，先儲存 data.length 到本地變數，提高 gas 效率
    function sumData() public view returns (uint sum) {
        uint len = data.length; // 將 length 先緩存至記憶體變數
        for (uint i = 0; i < len; i++) {
            sum += data[i];
        }
    }
}

// 測試案例：
// 1. 部署 FixedContract。
// 2. 呼叫 addData() 多次加入大量資料。
// 3. 呼叫 sumData() 進行總和計算，由於使用了本地變數 len 儲存 data.length，
//    此函式在迴圈中不再重複存取 storage，從而大幅降低 gas 消耗，解決 Inefficient Operation Sequence 漏洞。
