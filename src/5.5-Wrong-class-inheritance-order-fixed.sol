// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
 修正後版本說明：
 為解決 Wrong class inheritance order 的問題，我們改變 Sales 合約的繼承順序，
 將 WhitelistedBuyers 放在前面、Utils 放在後面，從而使得檢查邏輯的線性化順序改變：
  Sales -> Utils -> WhitelistedBuyers -> SalesCompl

  在此配置下，即使呼叫者在 whitelist 中，最終會經由 Utils 的 validPurchase() 檢查 cap 條件，
  無法僅依靠白名單條件來繞過 cap 限制。

 攻擊測試流程：
 1. 部署各基礎合約後，部署 Sales (採用繼承順序 WhitelistedBuyers, Utils) 合約。
 2. 攻擊者即便被列入白名單，但若超出 cap 限制，validPurchase() 會返回 false，交易失敗。
 3. Attack 合約呼叫 Sales.buy() 進行攻擊測試時，將無法繞過 cap 限制。
*/

contract SalesCompl {
    uint256 public startBlock;
    uint256 public endBlock;

    constructor() {
        startBlock = block.number;
        endBlock = block.number + 100; // 銷售期間為 100 個區塊
    }

    function validPurchase() internal view virtual returns (bool) {
        uint256 current = block.number;
        bool withinPeriod = (current >= startBlock && current <= endBlock);
        bool nonZeroPurchase = (msg.value != 0);
        return withinPeriod && nonZeroPurchase;
    }
}

contract Utils is SalesCompl {
    uint256 public cap;
    uint256 public weiRaised;

    constructor() {
        cap = 100 ether; // 設定購買上限
        weiRaised = 0;
    }

    function validPurchase() internal view virtual override returns (bool) {
        bool withinCap = (weiRaised + msg.value) <= cap;
        return super.validPurchase() && withinCap;
    }
}

contract WhitelistedBuyers is SalesCompl {
    mapping(address => bool) public whitelist;

    constructor() {
        whitelist[msg.sender] = true;
    }

    function validPurchase() internal view virtual override returns (bool) {
        return super.validPurchase() || (whitelist[msg.sender] && !hasEnded());
    }

    function hasEnded() internal view returns (bool) {
        return block.number > endBlock;
    }
}

// 修正後的 Sales 合約：調整繼承順序為 WhitelistedBuyers, Utils
contract Sales is WhitelistedBuyers, Utils {
    // 明確覆寫 validPurchase，解決多重繼承衝突
    function validPurchase() internal view override(WhitelistedBuyers, Utils) returns (bool) {
        // 根據線性化順序，將先執行 Utils.validPurchase 然後 WhitelistedBuyers.validPurchase，從而保留 cap 檢查
        return super.validPurchase();
    }

    // 對外買入函式
    function buy() public payable {
        require(validPurchase(), "Purchase not valid");
        weiRaised += msg.value;  // 更新累計募集金額
    }

    function checkValid() public view returns (bool) {
        return validPurchase();
    }
}

// 攻擊合約：模擬攻擊者利用原漏洞進行攻擊
// 在此修正版本中，攻擊將失敗，因為 cap 會正確檢查
contract Attack {
    Sales public fixedSales;

    constructor(address _sales) {
        fixedSales = Sales(_sales);
    }

    function attack() public payable {
        fixedSales.buy{value: msg.value}();
    }

    receive() external payable {}
}
