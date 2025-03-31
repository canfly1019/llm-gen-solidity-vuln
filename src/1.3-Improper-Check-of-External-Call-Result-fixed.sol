// SPDX-License-Identifier: UNLICENSED
// Fixed Contract for Properly Checking External Call Result
// 修正方法：在 withdraw 函式中，外部呼叫後必須使用 require() 來確認回傳結果為 true，
// 若外部呼叫失敗則 revert 交易，避免後續邏輯錯誤。

pragma solidity >=0.8.0;

contract FixedContract {
    // 狀態變數：記錄每個地址存入的 Ether 數量
    mapping(address => uint256) public balances;

    // 存款函式，接收 Ether 並更新餘額
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 修正後的 withdraw 函式，正確檢查外部呼叫之回傳值
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        // 更新狀態變數，扣除提領金額
        balances[msg.sender] -= amount;
        
        // 正確的外部呼叫：在呼叫後檢查 success，如果失敗則 revert
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "External call failed"); // 修正重點：必須確認外部呼叫回傳成功
    }

    // 接收 Ether 的函式
    receive() external payable {}
}

// 攻擊測試說明：
// 1. 與 Vulnerable 版本相同，攻擊合約仍採用強制 revert 的 fallback 函式，
// 2. 此時若 AttackContractFixed 嘗試從 FixedContract 提領 Ether，將因 require(success, ...) 而 revert，避免資金處理錯誤。

contract AttackContractFixed {
    FixedContract public fixedContract; // 將變數名稱從 fixed 改為 fixedContract 避免使用保留字

    // 修改建構子參數型別為 address payable 以符合要求
    constructor(address payable _fixed) {
        fixedContract = FixedContract(_fixed);
    }

    // 攻擊合約的 fallback 函式，模擬外部呼叫失敗
    fallback() external payable {
        revert("AttackContractFixed: Fallback revert");
    }

    // （可選）若需要也可實作 receive 函式
    // receive() external payable { revert("AttackContractFixed: Receive revert"); }

    // 存款到 FixedContract
    function deposit() external payable {
        fixedContract.deposit{value: msg.value}();
    }

    // 發起提領，觸發 FixedContract 的 withdraw 函式
    function attackWithdraw(uint256 amount) external {
        fixedContract.withdraw(amount);
    }

    // 查詢合約餘額
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
