// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
修正後程式碼說明:
原本漏洞在於直接呼叫不受信任的外部網路服務，其回傳資料無法驗證真實性，可能導致差異化結果與攻擊之風險。
修正方式改為利用 off-chain 可信任者所簽章資料，並在合約內驗證該簽章，確保更新的數值來源可信。

原修正版本依賴 OpenZeppelin 的 ECDSA 庫，但在環境中導入失敗，故在此將 ECDSA 庫程式碼內嵌於合約內，確保編譯通過。
*/

// Minimal ECDSA library 內嵌實作 (參考 OpenZeppelin 實作)
library ECDSA {
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        // 進行簽章分解
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
        
        // 利用 ecrecover 取得簽章者位址
        return ecrecover(hash, v, r, s);
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 生成 Ethereum 簽章前置字串的 hash
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

contract FixedContract {
    using ECDSA for bytes32;
    
    // trustedSigner 為可信任的數據提供者，只有此位址所簽章之資料才被接受
    address public trustedSigner;
    uint public value;

    // 建構子設定 trustedSigner
    constructor(address _trustedSigner) {
        trustedSigner = _trustedSigner;
    }

    // updateValue 函式要求提供已簽章資料，來自可信任的數據提供者，避免外部隨意操控
    function updateValue(uint _value, bytes memory signature) public {
        // 建立訊息 hash，包含待更新數值與呼叫者位址，以避免重放攻擊
        bytes32 messageHash = keccak256(abi.encodePacked(_value, msg.sender));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // 驗證簽章是否來自 trustedSigner
        require(ethSignedMessageHash.recover(signature) == trustedSigner, "Invalid signature");
        
        // 驗證通過，安全地更新數值
        value = _value;
    }
}

/*
修正後測試步驟:
1. 部署 FixedContract 時，指定一個可信任的 signing address，該位址將用於提供已簽章數據。
2. Off-chain 由 trustedSigner 使用私鑰簽署訊息： keccak256(abi.encodePacked(value, user address))，得到 signature。
3. 呼叫 updateValue() 並傳入數值及 signature，合約將先驗證簽章後再更新狀態。

注意：此修正版本假設 off-chain 簽章及 trustedSigner 安全性均已保障，不會受到外部操控影響。
*/
