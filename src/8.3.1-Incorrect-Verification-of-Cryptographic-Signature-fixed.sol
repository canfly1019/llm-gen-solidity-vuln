// Fixed Contract 示例：修正 Incorrect Verification of Cryptographic Signature
// 修正方式：在驗證簽名過程中正確加入 Ethereum Signed Message 前綴，確保訊息的
// 真實性與完整性，使攻擊者無法偽造合法簽名。

pragma solidity >=0.8.0;

// 因為在本地編譯環境中找不到 @openzeppelin 套件，故在此內嵌一個最小版本的 ECDSA library
library ECDSALib {
    // 依據 EIP-191 將 hash 轉換成 Ethereum Signed Message hash
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 透過組合標準前綴與原 hash，生成符合 EIP-191 的 hash
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    // recover 函式從簽名中取得簽署者地址
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        // 使用 assembly 從簽名中讀取組件 r, s, v
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return ecrecover(hash, v, r, s);
    }
}

contract Fixed {
    using ECDSALib for bytes32;

    // 狀態變數：記錄授權簽署者地址 (修正後的重點變數)
    address public authorizedSigner;
    
    // 狀態變數：儲存已處理訊息的雜湊 (修正後的重點變數)
    bytes32 public lastProcessedHash;

    constructor(address _authorizedSigner) {
        authorizedSigner = _authorizedSigner;
    }

    // 修正後的函式：正確處理訊息簽名驗證
    function processMessage(string memory message, bytes memory signature) public {
        // 計算訊息的 hash
        bytes32 messageHash = keccak256(abi.encodePacked(message));
        // 加入標準的以太坊前綴，形成符合 EIP-191 規定的 signed message hash (修正關鍵)
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // 從簽名中還原出 signer 地址，使用內嵌的 ECDSALib library 進行正確驗證
        address signer = ethSignedMessageHash.recover(signature);
        require(signer == authorizedSigner, "Not authorized");
        
        // 更新已處理訊息的 hash
        lastProcessedHash = keccak256(abi.encodePacked(lastProcessedHash, messageHash));
    }
}

// 測試示例合約：AttackFixed
// 該示例展示若攻擊者試圖使用重放攻擊，由於正確使用前綴，將無法偽造有效簽名
contract AttackFixed {
    Fixed public fixedContract;

    // 在部署時指定 Fixed 合約地址
    constructor(address _fixedAddress) {
        fixedContract = Fixed(_fixedAddress);
    }

    // 攻擊流程：
    // 攻擊者試圖傳入任意訊息與重放的簽名，但因為簽名必須匹配正確的前綴後資料，故無法通過驗證
    function attack(string memory arbitraryMessage, bytes memory signature) public {
        // 呼叫 fixedContract.processMessage，若簽名不正確，則 revert
        fixedContract.processMessage(arbitraryMessage, signature);
    }
}

/*
部署與測試步驟說明：
1. 部署 Fixed 合約，設定授權簽署者地址，此地址持有正確私鑰。
2. 授權簽署者使用標準以太坊前綴對正確訊息進行簽署。
3. 攻擊者若試圖重放或偽造簽名，即使修改訊息內容也無法通過驗證，因為 recover 過程
   已正確處理前綴，保證訊息完整性。
4. 部署 AttackFixed 合約，並嘗試呼叫 attack() 函式，將失敗於 require 驗證階段。
*/