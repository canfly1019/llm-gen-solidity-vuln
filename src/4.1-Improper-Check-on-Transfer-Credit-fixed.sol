pragma solidity >=0.8.0;

/*
修正版本說明:
1. 在 withdraw() 函式中，僅在確認 ETH 成功轉出後才清空使用者餘額。
2. 若轉帳失敗，則 revert 整個交易，避免賬戶被錯誤清零，保障資金正確性。

測試步驟:
1. 部署 SimpleBankFixed 合約。
2. 從任意地址呼叫 deposit() 存入 ETH。
3. 呼叫 withdraw()，若轉帳成功才會清空餘額；若接收方拒絕接收 ETH (例如使用攻擊合約 RevertingReceiver)，則交易會被 revert。

注意：
原本程式碼中 revert 的錯誤訊息中文可能會造成編譯錯誤，因此此處訊息改為英文。
*/

contract SimpleBankFixed {
    // 使用者餘額映射
    mapping(address => uint) public balances;

    // deposit 函式：允許存入 ETH
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // withdraw 函式：修正後，僅在成功轉帳後才清空餘額
    function withdraw() external {
        uint amount = balances[msg.sender];
        // 僅當轉帳成功後，才更新使用者餘額；若失敗則 revert
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        balances[msg.sender] = 0;
    }
}

// 範例 Helper 合約：NormalReceiver
// 此合約設計為正常接收 ETH，不會造成轉帳失敗
contract NormalReceiver {
    // fallback 函式，允許接收 ETH
    fallback() external payable {}
    
    // receive 函式，允許接收 ETH
    receive() external payable {}
}
