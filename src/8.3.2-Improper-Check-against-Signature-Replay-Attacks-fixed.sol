pragma solidity >=0.8.0;

// 修正後的合約 Fixed
// 修正重點：在計算訊息雜湊時不再包含 signature，並額外檢查 signature 中 s 與 v 的合法性，避免簽名 malleability

contract Fixed {
    // 狀態變數：儲存已處理過的訊息雜湊，僅包含必要訊息
    mapping(bytes32 => bool) public processedHashes;

    address public signer;

    constructor(address _signer) {
        signer = _signer;
    }

    // processMessage 函式修正後僅以合約地址與訊息計算雜湊，避免包含 signature
    function processMessage(string memory _message, bytes memory signature) public {
        // 修正：訊息雜湊只包含合約地址與 _message
        bytes32 messageHash = keccak256(abi.encodePacked(address(this), _message));
        require(!processedHashes[messageHash], "Message already processed");

        // 生成 Ethereum 標準的簽名雜湊
        bytes32 ethSignedMessageHash = toEthSignedMessageHash(keccak256(abi.encodePacked(_message)));
        address recovered = recoverSigner(ethSignedMessageHash, signature);
        require(recovered == signer, "Invalid signature");

        processedHashes[messageHash] = true;

        // 進行業務邏輯 (示意代碼)
    }

    // 生成 Ethereum Signed Message 雜湊
    function toEthSignedMessageHash(bytes32 _hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    // 回復簽名者地址，並加入針對 s 與 v 的額外限制以避免 malleability 攻擊
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        
        // 限制 s 值必須介於下列範圍，避免 signature malleability (參考 secp256k1 標準)
        require(uint256(s) <= 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0, "Invalid signature 's' value");

        // 限制 v 只能是 27 或 28
        require(v == 27 || v == 28, "Invalid signature 'v' value");

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
}

// 攻擊範例說明：
// 在修正後的合約中，由於計算訊息雜湊時不包含 signature，因此若攻擊者試圖修改 signature 產生不同的變體，其重放攻擊將無法通過 processedHashes 的檢查。
// 此外，額外加入的 s 與 v 的檢查降低了 signature malleability 的風險。