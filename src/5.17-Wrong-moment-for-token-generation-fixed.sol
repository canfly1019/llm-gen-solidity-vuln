pragma solidity >=0.8.0;

// 修正後合約：正確時機鑄幣 (Fixed token generation timing)
// 修正說明：
// 為避免任意鑄造代幣的漏洞，buyTokens 函式不再接受外部指定的 beneficiary，
// 改為直接將鑄造出的代幣記錄於 msg.sender。這樣可以確保只有購買者本人
// 才能接收到其支付 Ether 對應的代幣，避免攻擊者利用參數傳遞漏洞操縱市場價格。

contract FixedTokenSale {
    // 狀態變數：紀錄各地址的代幣餘額
    mapping(address => uint256) public balances;
    
    // 狀態變數：代幣售價，此處設為 1 ether 一枚代幣
    uint256 public tokenPrice = 1 ether;

    // 改進後的 buyTokens 函式，不再接受外部輸入的 beneficiary 參數
    function buyTokens() public payable {
        require(msg.value >= tokenPrice, "Insufficient Ether");
        
        // 僅根據 msg.sender 進行代幣鑄造，避免任意傳入 beneficiary 的風險
        uint256 tokens = msg.value / tokenPrice;
        balances[msg.sender] += tokens;
    }
}

// 攻擊範例（測試用）：
// 嘗試利用 AttackFixed 合約進行攻擊，但由於 buyTokens() 僅依賴 msg.sender，
// 因此無法將代幣轉移至攻擊者控制的其他地址。

contract AttackFixed {
    FixedTokenSale public fixedSale;
    address public attacker;

    // 部署時指定 FixedTokenSale 合約地址
    constructor(address _fixedSale) {
        fixedSale = FixedTokenSale(_fixedSale);
        attacker = msg.sender;
    }

    // 攻擊函式，但由於 FixedTokenSale 的 buyTokens 不接受 beneficiary，
    // 攻擊者只能獲得自己的代幣，無法利用漏洞進行任意鑄幣
    function attack() public payable {
        require(msg.sender == attacker, "Not authorized");
        fixedSale.buyTokens{value: msg.value}();
    }

    // 查詢攻擊者在修正合約中的代幣餘額（僅作示範）
    function getMyTokens() public view returns (uint256) {
        return fixedSale.balances(attacker);
    }
}

/*
部署與測試流程說明：
1. 部署 FixedTokenSale 合約。
2. 部署 AttackFixed 合約，並在部署時傳入 FixedTokenSale 合約地址。
3. 攻擊者呼叫 AttackFixed 合約中的 attack 函式，傳入足夠的 Ether（至少 1 ether）。
   此時，鑄造的代幣會直接記入呼叫者（msg.sender，即攻擊者）的餘額，
   無法通過傳入其他 beneficiary 來操縱代幣價格。
*/