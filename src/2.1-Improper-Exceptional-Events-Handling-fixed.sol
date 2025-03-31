// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// FixedContract 合約修正版：修正 Improper Exceptional Events Handling 漏洞
// 修正重點：在 withdraw 函式進行 Ether 傳送後，檢查回傳值，若轉帳失敗則 revert，確保操作的原子性

contract FixedContract {
    mapping(address => uint) public balances; // 狀態變數

    // 存款函式
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 修正 withdraw 函式：在 low-level call 後檢查回傳值並使用 require，確保例外事件得以正確處理
    function withdraw() external {
        uint amount = balances[msg.sender];
        require(amount > 0, "No balance");
        // 更新狀態先
        balances[msg.sender] = 0;
        // 修正：檢查回傳值，若失敗則 revert，確保操作的原子性
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // 接收 Ether 的函式
    receive() external payable {}
}

// 攻擊合約針對修正版本的最小可行攻擊範例：
// 修正合約 AttackContractFixed（變數名稱不再使用 reserved 關鍵字 fixed，而改成 fixedContract）
// 攻擊合約與前述 VulnerableContract 相同，但由於 FixedContract 有檢查回傳值，
// 若 AttackContractFixed 的 fallback 故意 revert，withdraw 會 revert 並回滾整個交易，因此攻擊失敗。

contract AttackContractFixed {
    FixedContract public fixedContract;

    // 修改建構子，將 _fixedAddress 設為 address payable 以解決類型轉換錯誤
    constructor(address payable _fixedAddress) {
        fixedContract = FixedContract(payable(_fixedAddress));
    }

    // fallback 函式，故意 revert
    fallback() external payable {
        revert("Fallback always fails");
    }

    // 嘗試透過攻擊呼叫 withdraw
    function attack() external payable {
        require(msg.value > 0, "Send ETH");
        fixedContract.deposit{value: msg.value}();
        // 此 withdraw 呼叫會因 fallback 失敗而立即 revert，整個交易回滾，確保資金安全
        fixedContract.withdraw();
    }
}

/*
繁體中文說明：
在修正版本 FixedContract 中，withdraw 函式在進行 Ether 的低階呼叫後，會檢查 call 的回傳值。
使用 require(success, "Transfer failed") 可確保若外部呼叫失敗，整個交易會 revert 並回滾所有狀態變數的改變。
因此，即使攻擊者透過惡意合約觸發 fallback revert，也無法破壞操作原子的要求，避免了 Improper Exceptional Events Handling 漏洞。
*/