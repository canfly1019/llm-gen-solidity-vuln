// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// 修正後的合約示範 Proper Protection of Sensitive Data
// 透過存取控制來保護敏感資料，只允許擁有者存取敏感資訊

contract SensitiveVaultFixed {
    string private secretData;  // 敏感資料
    address private owner;      // 合約擁有者

    // 設定擁有者及敏感資料
    constructor(string memory _secret) {
        secretData = _secret;
        owner = msg.sender;
    }

    // 只有合約擁有者能夠取得敏感資料，防止未授權的存取
    function getSecret() public view returns (string memory) {
        require(msg.sender == owner, "Unauthorized access");
        return secretData;
    }
}

// 嘗試攻擊 Fixed 合約的攻擊合約範例：
contract AttackFixed {
    SensitiveVaultFixed public fixedContract;
    event AttemptedLeak(string secret);

    constructor(address _fixedAddress) {
        fixedContract = SensitiveVaultFixed(_fixedAddress);
    }

    // 攻擊者嘗試呼叫 getSecret() 方法，預期會因授權失敗而 revert
    function attack() public {
        // 這裡將導致 revert，因為 msg.sender 非 owner
        string memory leaked = fixedContract.getSecret();
        emit AttemptedLeak(leaked);
    }
}

/*
部署與測試步驟：
1. 部署 SensitiveVaultFixed 合約，並使用部署者帳號建立，例如使用敏感資料 "MySecretPassword"。
2. 使用另一個非 owner 帳號部署 AttackFixed 合約，並填入 SensitiveVaultFixed 合約地址。
3. 呼叫 AttackFixed 合約的 attack() 方法，會因 require 欄位失敗而 revert，
   從而證明敏感資料已獲得適當的保護，非授權者無法取得。
*/