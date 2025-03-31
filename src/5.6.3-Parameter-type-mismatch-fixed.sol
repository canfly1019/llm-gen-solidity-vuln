pragma solidity >=0.8.0;

// 修正後說明：
// 介面及其實作中，transfer() 所使用的參數型態必須一致，這裡統一使用 uint32。

interface Token {
    function transfer(uint32 value) external returns (bool);
}

contract GoodToken is Token {
    // 正確實作 transfer()，參數型態與介面一致
    function transfer(uint32 value) external override returns (bool) {
        return true;
    }
}

contract Wallet {
    // 呼叫時使用正確的參數型態，確保呼叫到正確的函式
    function transfer(address token, uint32 value) external {
        require(Token(token).transfer(value), "Transfer failed");
    }
}

// 測試合約：
// 1. 部署 Wallet
// 2. 部署 GoodToken (實作正確的 transfer 函式)
// 3. 呼叫 AttackFixed.executeAttack，發現因為型態一致，因此無法利用漏洞

contract AttackFixed {
    Wallet public wallet;
    GoodToken public goodToken;
    
    constructor(Wallet _wallet) {
        wallet = _wallet;
        goodToken = new GoodToken();
    }
    
    // 嘗試進行攻擊，但由於介面和實作一致，這裡的呼叫會執行預期內的流程，不存在漏洞
    function executeAttack(uint32 value) public {
        wallet.transfer(address(goodToken), value);
    }
}
