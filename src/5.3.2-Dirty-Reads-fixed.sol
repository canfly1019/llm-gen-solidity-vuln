// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
  固定後程式碼說明：
  修正方式：將狀態變數的更新操作移至先，然後才進行外部 callback 呼叫，確保 callback 中讀取的值為最新狀態。

  攻擊者若再呼叫 updateValueAndNotifyFixed()，則在 callback 階段讀取到的 value 為更新後的正確數值，從而避免髒讀問題。
*/

interface IAttackerFixed {
    function notify(uint currentValue) external;
}

contract FixedContract {
    uint public value;
    
    constructor() {
        value = 0;
    }
    
    // 修正後函式：先更新 state variable，再做 callback，確保外部獲取正確的資料
    function updateValueAndNotifyFixed(uint newValue, address callbackAddr) public {
        // 先更新 state variable，避免髒讀
        value = newValue;
        
        // 讀取更新後的新值
        uint currentValue = value;
        
        // 呼叫外部 callback，傳遞最新的值
        IAttackerFixed(callbackAddr).notify(currentValue);
    }
}

// 使用者範例合約，模擬接收 callback 的動作
contract Receiver {
    FixedContract public fixedContract;
    uint public receivedValue;
    
    event Notified(uint currentValue);
    
    constructor(address fixedContractAddr) {
        fixedContract = FixedContract(fixedContractAddr);
    }
    
    // 呼叫 updateValueAndNotifyFixed 來進行資料更新與 callback
    function executeUpdate(uint newValue) external {
        fixedContract.updateValueAndNotifyFixed(newValue, address(this));
    }

    // 回調函式，將接收到的最新 value 記錄下來
    function notify(uint currentValue) external {
        receivedValue = currentValue;
        emit Notified(currentValue);
    }
}
