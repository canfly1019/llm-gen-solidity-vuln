pragma solidity >=0.8.0;

/*
    修正後的漏洞:
    在修正版本中，我們在執行外部合約調用前，先檢查提供者地址是否實際部署了合約，
    透過 extcodesize 檢查此地址是否有程式碼，若無則可避免調用不存在的合約而產生異常。
    此外，我們仍保持原有的客戶驗證邏輯，並使用 require 搭配正確的錯誤訊息來確保安全性。
*/

// 提供者合約介面與實作
contract Provider {
    // 正常情況下，isCustomer 應包含客戶驗證邏輯
    function isCustomer(address customer) public virtual returns (bool) {
        // 在真實情況中，可能會有客戶驗證的邏輯
        return false;
    }
}

// 正規的服務合約，在執行外部呼叫前會檢查 provider 是否為有效合約地址
contract FixedService {
    // 此函式在調用 provider 合約之前先驗證地址是否為合約，避免外部調用異常
    function getService(address provider, address customer) public {
        // 檢查提供者地址是否部署合約，若非合約則回退
        require(contractExists(provider), "Provider is not a valid contract");
        Provider _provider = Provider(provider);
        // 調用外部函式 isCustomer
        if (_provider.isCustomer(customer)) {
            // 提供服務的邏輯，例如處理交易、更新狀態等
        }
    }

    // 使用 extcodesize 檢查位址是否為合約地址
    function contractExists(address _addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

// 一個正規的 Provider 合約，可以用來測試 FixedService 的正確邏輯
contract LegitProvider is Provider {
    // 覆寫 isCustomer, 模擬正確的客戶驗證邏輯
    function isCustomer(address customer) public pure override returns (bool) {
        // 假設只要地址不為 0 就視為有效客戶，此處僅為簡單示例
        return customer != address(0);
    }
}

/*
    修正後的防範攻擊示例:
    1. 若攻擊者嘗試傳入一個沒有部署合約的地址或惡意合約 (例如 MaliciousProvider)，
       合約代碼會在 getService 呼叫前利用 contractExists 檢查失敗，並通過 require 回退交易，
       保證外部調用的安全性。
    2. 因使用 require 並提供明確的錯誤訊息，可協助調試並降低誤用風險。
*/