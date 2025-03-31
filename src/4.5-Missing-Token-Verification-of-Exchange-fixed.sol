pragma solidity >=0.8.0;
// SPDX-License-Identifier: UNLICENSED

// 本範例中修正漏洞的方法：
// 進行 token 轉帳前後的餘額檢查，以確保實際 token 金額有轉入。
// 此外，也建議使用 OpenZeppelin SafeERC20 庫，但下列示例採用手動檢查作為示範。

interface IERC20 {
    // 此處 transferFrom 按標準 ERC20 實作，不回傳 bool (但假設如實拋出錯誤)
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

/**
 * FixedExchange 合約為修正版，增加了 token 轉入前後的餘額檢查，確保實際轉帳成功
 */
contract FixedExchange {
    // tokens[token 地址][使用者地址] = deposit 金額
    mapping(address => mapping(address => uint256)) public tokens;

    // Deposit 事件
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);

    // 將函式標記為 payable 以解決對 msg.value 的引用問題
    function depositToken(address token, uint256 amount) public payable {
        require(msg.value == 0, "No Ether allowed");
        require(token != address(0), "Invalid token address");

        // 取得合約在 token 中的餘額
        uint256 beforeBalance = IERC20(token).balanceOf(address(this));

        // 呼叫 transferFrom，依照標準，此函式應實際將 token 轉入本合約
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // 轉帳後再次取得餘額以驗證實際轉入數量
        uint256 afterBalance = IERC20(token).balanceOf(address(this));
        require(afterBalance - beforeBalance == amount, "Token transfer amount mismatch");

        tokens[token][msg.sender] += amount;
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
}

/**
 * RealToken 為符合 ERC20 標準實作的正常 token，其 transferFrom 真正扣減 balance
 * 使用 RealToken 進行 deposit 時，FixedExchange 能正確驗證餘額變化，避免攻擊者利用虛假 token 攻擊
 */
contract RealToken {
    string public name = "RealToken";
    string public symbol = "REAL";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
    }

    function transferFrom(address from, address to, uint256 amount) public {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

/**
 * FakeTokenForFixed 模擬一個惡意 token，其 transferFrom 並未進行實際 token 轉移
 * FixedExchange 透過餘額檢查可捕捉此行為，從而拒絕虛假 deposit
 */
contract FakeTokenForFixed {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        // 初始沒有任何 token，避免虛假轉移
        balanceOf[address(this)] = 0;
    }

    // 此 transferFrom 故意不改變餘額，使得 FixedExchange 檢查失敗
    function transferFrom(address /*from*/, address /*to*/, uint256 /*amount*/) public pure {}
}

/**
 * FixedAttack 合約示範在 FixedExchange 中利用 FakeTokenForFixed 進行攻擊
 * 但由於 FixedExchange 已採用轉帳前後餘額檢查，因此攻擊將會失敗。
 */
contract FixedAttack {
    FixedExchange public fixedExchange;
    FakeTokenForFixed public fakeToken;
    address public owner;

    constructor(FixedExchange _fixedExchange) {
        fixedExchange = _fixedExchange;
        fakeToken = new FakeTokenForFixed();
        owner = msg.sender;
    }

    // 嘗試利用 FakeTokenForFixed 進行 deposit 攻擊，但 FixedExchange 會因餘額不符而 revert
    function executeAttack(uint256 depositAmount) public {
        fixedExchange.depositToken{value: 0}(address(fakeToken), depositAmount);
    }
}
