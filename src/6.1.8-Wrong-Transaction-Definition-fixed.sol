// Fixed Code (修正後的版本：使用延期動作以避免 inline 呼叫回滾整個交易)
// 修正方法是將外部呼叫動作與狀態改變分離，
// 當外部呼叫失敗時，不直接回滾交易，而是將失敗的款項記錄下來，
// 讓用戶可以在日後以單獨交易方式提領（deferred action）。

pragma solidity >=0.8.0;

contract FixedContract {
    // 狀態變數：累計存入的 Ether
    uint public total;
    
    // 用來記錄因外部呼叫失敗而待提領的餘額
    mapping(address => uint) public pendingWithdrawals;

    // execute() 函式先更新狀態，再嘗試進行外部呼叫。
    // 若外部呼叫失敗，則將金額記錄到 pendingWithdrawals 中，
    // 以避免整個交易因為 inline 外部呼叫的失敗而回滾。
    function execute() public payable {
        // 狀態更新：累計存入的金額
        total += msg.value; // <-- 此處正常更新狀態

        // 試著回傳 Ether 給呼叫者
        (bool success, ) = payable(msg.sender).call{value: msg.value}("");
        if (!success) {
            // 如果失敗，不回滾交易，而是記錄該金額以供稍後提領
            pendingWithdrawals[msg.sender] += msg.value;
        }
    }
    
    // 用戶可呼叫 withdraw() 函式，從 pendingWithdrawals 中提領先前失敗的金額
    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        pendingWithdrawals[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
    }
    
    // fallback 接收 Ether
    receive() external payable {}
}

// 攻擊者合約範例，與漏洞版本類似，但在固定的版本中，
// 即使 Attacker 的 fallback 仍會 revert，也僅會將金額記錄為待提領，
// 不會回滾整個 execute() 的狀態更新，從而降低攻擊成功率。
contract AttackerFixed {
    // fallback 函數仍然保持 revert 行為
    receive() external payable {
        revert("AttackFixed: reverting on receiving funds");
    }

    // 攻擊入口：試圖呼叫 FixedContract.execute 並傳送 Ether
    function attack(address _fixed) public payable {
        (bool success, ) = _fixed.call{value: msg.value}(abi.encodeWithSignature("execute()"));
        require(success, "AttackFixed failed");
    }
}

/*
修正版本說明：
1. 在 FixedContract.execute() 中，合約會先更新 total 狀態，
   接著嘗試將收到的 Ether 回傳給 msg.sender。
2. 如果外部呼叫因為攻擊者合約的 fallback 失敗，則該 Ether 不會導致整個交易回滾，
   而是將數額記錄在 pendingWithdrawals 中，供用戶之後透過 withdraw() 單獨提領。
3. 這種設計模擬了 EOSIO 的 defer actions，將有風險的動作延期到另一筆交易中執行，
   以降低因 inline 呼叫失敗而產生的連鎖回滾風險。

攻擊測試流程：
1. 部署 FixedContract 與 AttackerFixed 合約。
2. 攻擊者從 AttackerFixed 呼叫 attack() ，並傳入 Ether。
3. FixedContract.execute() 呼叫時，因為 AttackerFixed 的 fallback 會 revert，
   但 Ether 會被記錄在 pendingWithdrawals，而非回滾整個交易。
4. 攻擊者可嘗試提領，但由於 fallback 中的 revert，提領也會失敗，
   減少了攻擊者干擾合約正常操作的可能性。
*/