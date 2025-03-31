// FixedToken.sol
// 此版本修正了 Missing Thrown Exception 漏洞，當轉帳條件不成立時，會即時使用 revert 拋出錯誤，確保呼叫者可以正確捕捉問題。

pragma solidity >=0.8.0;

contract FixedToken {
    mapping(address => uint256) public balances; // 狀態變數：記錄地址 token 餘額
    
    // ERC20 的 Transfer 事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // 建構子，將初始餘額全部給部署者
    constructor(uint256 initialSupply) {
        balances[msg.sender] = initialSupply;
    }
    
    // 修正後的 transfer 函式：若餘額不足或 value 不合法，直接 revert 拋出錯誤
    function transfer(address to, uint256 value) public returns(bool success) {
        require(balances[msg.sender] >= value && value > 0, "transfer failed: insufficient balance or invalid value");
        
        // 以下兩行為修正重點，當條件不成立時，require 會中斷交易，保證狀態不變
        balances[msg.sender] = substractSafely(balances[msg.sender], value);
        balances[to] = addSafely(balances[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function substractSafely(uint256 a, uint256 b) internal pure returns(uint256) {
        return a - b;
    }
    
    function addSafely(uint256 a, uint256 b) internal pure returns(uint256) {
        return a + b;
    }
}

// 攻擊合約：AttackFixedToken
// 此攻擊合約示範在固定版本中，因 transfer 內部會使用 revert，故當轉帳條件不符時，攻擊將無法繼續

contract AttackFixedToken {
    FixedToken public token;

    // 部署前需提供 FixedToken 合約地址
    constructor(address tokenAddress) {
        token = FixedToken(tokenAddress);
    }

    // 試圖用不足餘額觸發 transfer，固定版會 revert，因此此函式捕捉錯誤並回傳 false
    function attackTransferWithInsufficientBalance() public returns (bool) {
        try token.transfer(address(this), 1000) returns (bool result) {
            return result;
        } catch {
            // 由於條件不符，transfer() 觸發 revert，防止了不明顯的錯誤狀態
            return false;
        }
    }
}
