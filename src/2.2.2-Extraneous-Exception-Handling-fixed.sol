// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
說明：
修正後的合約移除了 extraneous exception handling 的 require 條件，符合標準要求，不再額外限制轉帳值，
使得 transferFrom 函式僅依照必要條件檢查（例如餘額不足）進行操作。

測試步驟：
(1) 部署 FixedToken 合約；
(2) 用部署者 address 取得初始 balance；
(3) 攻擊者部署 FixedAttackContract 並設定 FixedToken 地址；
(4) 攻擊者呼叫 FixedAttackContract.attack()，傳入合法數值（例如 25 wei 或其他），因為不再有額外限制，
    轉帳操作只會依據餘額檢查而非額外 require 條件，正常執行轉帳，或者依照業務邏輯進行處理。
*/

contract FixedToken {
    mapping(address => uint) public balances;
    
    // 初始化部署者擁有 1000 wei 的代幣
    constructor() {
        balances[msg.sender] = 1000;
    }
    
    // 修正後的 transferFrom 函式，移除了非必要的 require 條件，僅保留正確檢查
    function transferFrom(address _spender, uint _value) public returns (bool success) {
        // 移除 require(_value < 20 wei) 的額外檢查
        require(balances[msg.sender] >= _value, "Insufficient balance");
        
        balances[msg.sender] -= _value;
        balances[_spender] += _value;
        return true;
    }
    
    // 查詢餘額
    function getBalance(address account) public view returns (uint) {
        return balances[account];
    }
}

// 攻擊（測試）合約：在修正後的合約中，攻擊者嘗試使用任意數值轉帳
contract FixedAttackContract {
    FixedToken public fixedToken;
    
    // 初始化時設定被測試的 FixedToken 合約地址
    constructor(address _fixedTokenAddress) {
        fixedToken = FixedToken(_fixedTokenAddress);
    }
    
    // 測試函式，傳入一個原本在 VulnerableToken 中會被拒絕的數值，但在這裡可正常轉帳
    function attack() public {
        // 傳入 25 wei ，此操作在 FixedToken 中能夠成功執行（前提是呼叫者有足夠的餘額）
        fixedToken.transferFrom(msg.sender, 25 wei);
    }
}
