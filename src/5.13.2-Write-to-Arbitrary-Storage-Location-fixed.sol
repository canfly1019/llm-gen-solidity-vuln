// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
修正後的程式碼說明：
1. PopBonusCode 函式修正了錯誤的 require 條件，確保在執行 pop 操作前，bonusCodes 陣列為非空狀態。
2. 移除直接操作 bonusCodes.length 的方式，改以使用內建的 pop() 函式安全移除最後一個元素，避免下溢問題。
此修正有效防止利用下溢漏洞改寫其他儲存槽（例如 owner）的攻擊方式。
*/

contract Wallet {
    uint[] public bonusCodes;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function PushBonusCode(uint c) public {
        bonusCodes.push(c);
    }

    function PopBonusCode() public {
        // 正確檢查 bonusCodes 陣列是否非空
        require(bonusCodes.length > 0, "No bonus codes to pop");
        // 使用安全的 pop() 方法移除陣列最後一個元素，避免直接修改長度
        bonusCodes.pop();
    }

    function UpdateBonusCodeAt(uint idx, uint c) public {
        require(idx < bonusCodes.length, "Index out of bound");
        bonusCodes[idx] = c;
    }
}

/*
測試說明：
在修正版本中，PopBonusCode 會先確認 bonusCodes 陣列非空，再透過 pop() 安全地刪除元素，
因此無法觸發下溢，攻擊者亦無法利用 UpdateBonusCodeAt 改寫其他儲存槽（例如 owner）。
*/
