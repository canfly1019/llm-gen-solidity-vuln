// SPDX-License-Identifier: UNLICENSED
// Fixed Solidity Code (Corrected Control Flow) - 本版本修正了流程控制漏洞
// 修正說明：在 execute 函式中，當 _flag 為1時，正確使用 return 中止後續流程，以防止敏感操作被執行

pragma solidity >=0.8.0;

contract FixedContract {
    // 敏感狀態變數
    uint public sensitiveData;

    // execute 函式根據 _flag 正確控制流程
    function execute(uint _flag) public payable {
        if(_flag == 1) {
            // 當 _flag 為1時回傳 Ether後，使用 return 終止後續操作，避免修改 sensitiveData
            payable(msg.sender).transfer(msg.value);
            return; // 正確中斷流程
        }
        // 只有在 _flag != 1 時才執行敏感操作
        sensitiveData = 42;
    }

    // 接收 Ether 的 fallback 功能
    receive() external payable {}
}

// 測試攻擊合約：示範即便嘗試攻擊，由於流程正確，sensitiveData 不會被任意修改
contract AttackFixedContract {
    FixedContract public fixedInstance;

    // 修正地址轉換問題，使用 payable 關鍵字處理
    constructor(address _fixedAddress) {
        fixedInstance = FixedContract(payable(_fixedAddress));
    }

    // 攻擊步驟：
    // 即使攻擊者呼叫 attack 並傳送 Ether，由於修正了流程控制，sensitiveData 不會被修改。
    function attack() external payable {
        fixedInstance.execute{value: msg.value}(1);
    }
}

/*
部署與測試說明：
1. 部署 FixedContract 合約。
2. 部署 AttackFixedContract 合約時，將 FixedContract 的地址作為參數(需經過 payable 轉換處理)。
3. 呼叫 AttackFixedContract.attack 並傳入 Ether，由於 execute 函式中正確使用 return，中止後續流程，因此 sensitiveData 不會被改變。
*/
