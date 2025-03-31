// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
修正後版本說明:
  - 調整合約邏輯，不再依賴合約的整體餘額 (address(this).balance) 作為獎金來源。
  - 將遊戲獎金儲存在獨立變數 prizePool 中，並且只允許透過 StartGame 函式存入。
  - 移除或拒絕其他非遊戲操作所導致的 Ether 注入，以避免外部狀態干擾遊戲結果。
*/

contract GameFixed {
    address public questionSender;
    string public question;
    bytes32 public responseHash;
    uint256 public prizePool; // 專用變數儲存獎金池

    // Try 函式：檢查答案是否正確，並從預設的獎金池支付
    function Try(string calldata _response) external payable {
        require(msg.sender == tx.origin, "Do not use contracts");
        require(responseHash != 0x0, "Game not started");
        // 修改: 奖金來源僅來自 prizePool，而非 address(this).balance
        if (responseHash == keccak256(bytes(_response)) && msg.value > 1 ether) {
            uint256 payout = prizePool;
            prizePool = 0; // 清空獎金池避免重入攻擊
            payable(msg.sender).transfer(payout);
        }
    }

    // StartGame 函式: 僅接受來自遊戲發起者的資金作為獎金
    function StartGame(string calldata _question, string calldata _response) public payable {
        require(responseHash == 0x0, "Game already started");
        require(msg.value > 1 ether, "Insufficient stake for game");
        responseHash = keccak256(bytes(_response));
        question = _question;
        questionSender = msg.sender;
        prizePool = msg.value; // 僅記錄遊戲開始時存入的獎金
    }

    // 接收 Ether 的 fallback 函式，但直接轉入的 Ether 將被拒絕，以避免外部干擾獎金池
    receive() external payable {
        revert("Direct deposits not allowed");
    }
}

/*
修正後的安全說明:

1. 遊戲中獎金僅來自 StartGame 時由題目發送者存入的金額，並儲存在變數 prizePool 中。
2. 由於合約拒絕直接接受 Ether (透過 receive() 的 revert)，攻擊者無法藉由自我銷毀或其他方式注入額外資金，
   因此無法透過修改外部狀態(即合約餘額)來影響最終獎金金額。
3. 此外，立即將提領後的 prizePool 設為 0，預防重入攻擊的可能性。

這樣修改後，可以避免「Dependency on External State Data」漏洞所帶來的風險。
*/
