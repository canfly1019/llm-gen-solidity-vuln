// SPDX-License-Identifier: MIT
// Solidity version: 測試此漏洞與版本無關，但需要 Solidity >=0.8.0 支援最新語法
pragma solidity >=0.8.0;

/*
    修正後的程式碼說明：
      為了防止跨通道呼叫導致未授權操作，此版本增加了來源驗證，
      僅允許授權的通道（或合約位址）調用 updateMessage 函式。

    修正步驟：
      1. 在部署合約時，設置授權呼叫者位址 (authorizedChannel)。
      2. 利用 onlyAuthorized 修飾器，驗證 msg.sender 是否為授權通道。

    攻擊者若非 authorizedChannel，則無法修改狀態變數 lastMessage。
*/

contract FixedContract {
    // 狀態變數：紀錄最後接收到的訊息
    string public lastMessage;
    // 授權通道位址：僅此位址可執行 updateMessage
    address public authorizedChannel; // 修正重點：增加來源驗證

    // 建構子設定授權通道位址
    constructor(address _authorizedChannel) {
        authorizedChannel = _authorizedChannel;
    }

    // Modifier 用來驗證呼叫者是否為授權通道
    modifier onlyAuthorized() {
        require(msg.sender == authorizedChannel, "Not authorized");
        _;
    }

    // 僅允許授權通道調用，更新狀態
    function updateMessage(string memory _message) public onlyAuthorized {
        lastMessage = _message;
    }
    
    // 接收 Ether 的 fallback 實作
    receive() external payable {}
}

/*
    修正程式碼示範步驟：
      1. 部署 FixedContract 並於建構子傳入合法的授權通道位址。
      2. 攻擊者若嘗試呼叫 FixedContract.updateMessage()，將因為 msg.sender 不是授權通道而失敗。
      3. 只有授權通道（正確設定的位址）可以成功更新 lastMessage 變數。
*/
