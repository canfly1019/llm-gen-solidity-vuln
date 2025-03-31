pragma solidity >=0.8.0;

// 修正後的合約：移除了漏洞，並對 fallback 函式進行正確處理
contract RegisterUser {
    // 將用戶註冊功能明確設計為帶參數的函式
    function setNewUser(string calldata name) external returns (bool) {
        // 用戶註冊邏輯，例如：建立用戶記錄
        // 省略部分業務邏輯
        return true;
    }

    // 修正後的 fallback 函式：當呼叫不存在的函式時，直接 revert，回滾所有操作
    fallback() external payable {
        revert("Function does not exist");
    }

    // receive() 函式專門處理直接接收 Ether，可加入必要邏輯但避免改變敏感狀態
    receive() external payable {
        // 僅允許接收 Ether，不會修改任何狀態
    }
}

// 呼叫範例合約：正確呼叫存在的 setNewUser 函式
contract callExternalExample {
    function callRegisterUser(RegisterUser a, string calldata name) public returns (bool) {
        // 呼叫明確定義的函式，傳入參數，避免觸發 fallback
        bool success = a.setNewUser(name);
        return success;
    }
}

// 模擬攻擊合約：試圖呼叫不存在函式但因為 fallback() 已 revert，攻擊無法成功
contract Attacker {
    // 攻擊流程說明：
    // 攻擊者試圖透過呼叫不存在的函式來誘使 RegisterUser.fallback() 被觸發
    // 但由於 fallback() 會 revert，故此攻擊手法無法成功
    function attack(RegisterUser target) public payable {
        (bool success, ) = address(target).call{value: msg.value}(abi.encodeWithSignature("nonExistentFunction()"));
        require(success, "Attack failed");
    }
}
