// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
修正說明：
修改隨機數生成機制，避免直接使用易受操控之區塊變數，改以內部秘密種子做混雜，降低攻擊者預測可能性。

注意：
1. 為保持範例簡潔，改用 blockhash(block.number - 1) 來取代 block.prevrandao，
   請注意：此方式仍有其限制，實際生產環境建議使用 Chainlink VRF 等可信隨機數來源。
2. 確保更新內部秘密種子，使預測難度增加。
*/

contract SecureLottery {
    address public winner;
    address public owner;
    uint256 private secret; // 修正部：內部秘密種子，避免直接使用可預測變數

    // 建構子：設定 owner 並初始化 secret
    constructor() {
        owner = msg.sender;
        // 利用前一區塊的區塊雜湊與當前時間及 owner 初始化 secret
        // 注意：block.number 必須大於 0，此處假設部署時區塊高度足夠
        secret = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, owner)));
    }

    // 更新內部秘密種子，混合新的區塊資訊，避免攻擊者利用預測維度回推
    function updateSecret() internal {
        // 使用前一區塊雜湊來導入不確定性
        secret = uint256(keccak256(abi.encodePacked(secret, blockhash(block.number - 1), block.timestamp)));
    }

    // 買票函式，需支付 1 ETH
    function buyTicket() public payable {
        require(msg.value == 1 ether, "Require exactly 1 ETH");
        updateSecret();
        // 修正：使用內部秘密種子與 msg.sender 生成難以預測的隨機數
        uint256 random = uint256(keccak256(abi.encodePacked(secret, msg.sender))) % 10;
        if (random == 0) {
            winner = msg.sender;
            payable(winner).transfer(address(this).balance);
        }
    }

    // fallback 函式讓合約能接收 ETH
    receive() external payable {}
}

/*
使用步驟（修正版本）：
1. 部署 SecureLottery 合約。
2. 參與者透過呼叫 buyTicket() 進行遊戲，並支付 1 ETH。

由於內部秘密種子難以外部預知，攻擊者無法輕易預測隨機數，從而降低 Cryptography Misuse 帶來的風險。

建議生產環境仍考慮使用 Chainlink VRF 等解決方案確保隨機數安全。
*/
