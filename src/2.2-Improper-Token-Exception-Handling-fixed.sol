pragma solidity >=0.8.0;

// 同樣定義 ERC20 的介面
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// ---------------------------------------------------------------------------
// FixedTokenHandler 合約修正了 withdraw 函式，將檢查 token.transfer 的回傳值。
// 當 transfer 失敗時，require 將 revert 交易，避免因未處理異常而造成漏洞。
// ---------------------------------------------------------------------------
contract FixedTokenHandler {
    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    // withdraw 函式已修正：檢查 transfer 回傳值，若轉帳失敗則 revert
    function withdraw(uint256 amount) external {
        bool success = token.transfer(msg.sender, amount);
        require(success, "transfer failed"); // 修正重點：處理 token.transfer 的回傳結果
    }
}

// 測試步驟（繁體中文）：
// 1. 攻擊者或測試者部署 MaliciousToken（繼承自 IERC20），此合約可用前述 VulnerableTokenHandler 範例中的 MaliciousToken 做模擬。
// 2. 部署 FixedTokenHandler，並傳入 MaliciousToken 的地址。
// 3. 當使用者呼叫 withdraw 時，因為 MaliciousToken.transfer 仍會回傳 false，所以 require 將會 revert，避免不正確的執行結果
// 4. 此修正確保只有在 transfer 成功時，withdraw 才會成功執行，從而阻止由於不當異常處理導致的漏洞利用。