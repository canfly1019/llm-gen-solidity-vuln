pragma solidity >=0.8.0;

// 修正後的合約：加入權限檢查，防止任意使用者觸發合約自毀
contract XYZ {
    address public owner; // 合約擁有者，在部署時設置

    constructor() {
        owner = msg.sender;
    }

    // 修正漏洞：在 destroy 函數中加入 require 檢查，僅允許 owner 呼叫
    function destroy() public {
        require(msg.sender == owner, "Only owner can call destroy");
        selfdestruct(payable(msg.sender));
    }
}

// 攻擊合約：嘗試利用原漏洞，但在修正版中將因權限檢查失敗而無法成功
contract Attacker {
    XYZ public fixedContract;

    // 傳入修正後合約的地址
    constructor(address _fixedContract) {
        fixedContract = XYZ(_fixedContract);
    }

    // 攻擊步驟：呼叫 destroy 函數，預期由於 require 失敗而 revert
    function attack() external {
        // 此調用將因 require 驗證失敗而 revert，防止非擁有者將合約自毀
        fixedContract.destroy();
    }
}

/*
部署和測試流程說明：
1. 部署修正後的 XYZ 合約，owner 為部署者。
2. 非 owner 部署攻擊合約 Attacker，並傳入 XYZ 合約地址。
3. 當非 owner 呼叫 Attacker 合約中的 attack 函數時，由於 require(msg.sender == owner) 檢查失敗，攻擊將無法成功，合約不會被自毀。
*/