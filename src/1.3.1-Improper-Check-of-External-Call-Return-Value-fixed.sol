pragma solidity >=0.8.0;

// 以下為修正後的程式碼，針對 Improper Check of External Call Return Value 漏洞進行修復

contract Item {
    // 正常實作：當 addProduct 被呼叫時，應正確回傳執行狀態
    function addProduct() external returns (bool) {
        // 模擬邏輯：成功新增產品則回傳 true
        return true;
    }
}

contract ContractERP {
    uint public orderCount = 0;

    function newPurchaseOrder(Item product) public {
        // 修正：檢查產品新增是否成功
        bool result = product.addProduct();
        require(result, "addProduct failed"); // 如果 product.addProduct() 回傳 false，則 revert
        orderCount++;
    }
}

// 攻擊示範：此處模擬惡意合約，但由於 ContractERP 已檢查返回值，攻擊將會失敗
contract MaliciousItemFixed {
    // 攻擊者嘗試利用此函式讓返回值失敗
    function addProduct() external returns (bool) {
        return false; // 故意回傳 false 模擬失敗情況
    }
}

// 測試攻擊的合約，預期攻擊無法成功，因為 require 檢查會阻止後續流程
contract AttackFixed {
    ContractERP public erp;
    MaliciousItemFixed public maliciousItem;

    constructor() {
        erp = new ContractERP();
        maliciousItem = new MaliciousItemFixed();
    }

    // executeAttack() 會因為 require 檢查失敗而 revert
    function executeAttack() public {
        erp.newPurchaseOrder(Item(address(maliciousItem)));
    }
}

/*
修正後說明：
1. ContractERP 在呼叫 product.addProduct() 時，將返回值儲存至 result 變數，
   並使用 require(result, "addProduct failed") 作檢查，避免後續流程在產品新增失敗時繼續運行。
2. 如果攻擊者使用惡意合約（如 MaliciousItemFixed）傳入，則 addProduct() 回傳 false，
   使得 require 檢查失敗，整個交易 revert。
*/