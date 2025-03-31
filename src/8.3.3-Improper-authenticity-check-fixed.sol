// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
    修正後的程式碼：
    針對 Improper authenticity check 的漏洞，我們使用 ecrecover() 進行簽名驗證，確保
    傳入的 signature 來自於授權的簽名者 (authorizedSigner)。

    修正說明:
    1. 在部署合約時設置 authorizedSigner，該地址為預先授權的簽名者。
    2. 在 execute() 函數中，使用 keccak256() 對訊息進行雜湊，並加上 Ethereum 特有的前綴，
       然後用 ecrecover() 恢復出簽名者地址，最後與 authorizedSigner 比對。

    測試前置說明:
    1. 部署 FixedAuth 合約，並設定正確的 authorizedSigner。
    2. 使用離線工具對訊息 (例如 msg.sender 與 amount 的組合) 進行簽名，生成正確的 signature。
    3. 呼叫 execute() 時傳入 amount 以及離線簽署生成的 signature，若簽名正確，則函數執行成功，
       並進行相應轉帳操作。
*/

contract FixedAuth {
    address public authorizedSigner; // 預先授權的簽名者地址
    event Executed(address caller, uint256 amount);

    constructor(address _authorizedSigner) {
        authorizedSigner = _authorizedSigner;
    }

    // 使用 ecrecover() 進行正確的簽名驗證
    function execute(uint256 amount, bytes memory signature) public {
        // 檢查 signature 長度是否正確
        require(signature.length == 65, "Invalid signature length");

        // 產生訊息雜湊，訊息內容包含 msg.sender 與 amount (依合約需求可調整訊息內容)
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, amount));
        // 加上 Ethereum 的訊息前綴
        bytes32 ethSignedMessageHash = prefixed(messageHash);

        // 拆解簽名得到 r, s, v
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        address recovered = ecrecover(ethSignedMessageHash, v, r, s);
        require(recovered == authorizedSigner, "Signature verification failed");

        // 驗證通過後執行操作
        payable(msg.sender).transfer(amount);
        emit Executed(msg.sender, amount);
    }

    // 幫助函式：補充 Ethereum 訊息前綴 (EIP-191)
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    // 幫助函式：拆解 signature 為 (r, s, v)
    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // 用於接收 Ether 的 fallback 函數
    receive() external payable {}
}

/*
    注意:
    1. 離線簽名時，確保要簽名的訊息內容與 execute() 中使用的完全匹配，例如：
       keccak256(abi.encodePacked(recipient, amount))。
    2. 授權簽名者 (authorizedSigner) 的私鑰應安全保管，避免外洩導致進一步漏洞風險。
*/
