// Solidity Version: 使用 >=0.8.0 語法。
pragma solidity >=0.8.0;

// Fixed 合約，修正方式為檢查低階呼叫的回傳值，若失敗則 revert。
contract ReturnValueFixed {
    // 修正後的函式：對低階呼叫回傳的 success 變數進行檢查
    function callChecked(address callee) public {
        (bool success, ) = callee.call(abi.encodeWithSignature("doSomething()"));
        // 若低階呼叫失敗，則 revert，避免後續操作繼續執行
        require(success, "Low-level call failed");
    }
}

// 惡意合約，用以展示當呼叫 fixed 合約時，由於正確檢查回傳值而使呼叫失敗直接 revert
contract MaliciousForFixed {
    // fallback 函式故意 revert，模擬攻擊情境
    fallback() external payable {
        revert("Malicious fallback triggered.");
    }

    // 與被呼叫的函式對應之介面
    function doSomething() external pure returns (string memory) {
        return "This should not execute";
    }
}

// 攻擊示範合約，展示在固定後的版本中攻擊無法成功，因為 callChecked 會檢查返回值並 revert
// 注意：原始版本中的變數名稱 'fixed' 與 Solidity 關鍵字衝突，因此此處將變數名稱修改為 safeReturnValue
contract AttackFixed {
    ReturnValueFixed public safeReturnValue;
    MaliciousForFixed public malicious;

    // 部署時建立 Fixed 合約與 MaliciousForFixed 合約的實例
    constructor() {
        safeReturnValue = new ReturnValueFixed();
        malicious = new MaliciousForFixed();
    }

    // 攻擊流程：呼叫 safeReturnValue 合約的 callChecked 函式，由於 malicious 的 fallback revert，因此 require 將使整體交易 revert
    function attack() public {
        safeReturnValue.callChecked(address(malicious));
    }
}
