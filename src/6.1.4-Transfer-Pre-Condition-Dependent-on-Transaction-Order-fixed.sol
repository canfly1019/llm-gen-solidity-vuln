// Solidity version >=0.8.0
// 修正目標: 解決交易排序依賴問題。透過額外引入 txCounter 機制，確保買入（buy）交易在執行時能驗證當前狀態是否正確。

pragma solidity >=0.8.0;

// 修正後的合約
contract SolutionTransactionOrdering {
    // 狀態變數：
    // price: 產品的價格
    // txCounter: 每次價格改變時會遞增，作為交易排序的預置條件
    // owner: 合約擁有者
    uint256 public price;
    uint256 public txCounter;
    address public owner;

    // 事件宣告
    event Purchase(address indexed buyer, uint256 price);
    event PriceChange(address indexed owner, uint256 price);

    // 建構式
    constructor() {
        owner = msg.sender;
        price = 100;
        txCounter = 0;
    }

    // 修飾器：僅限 owner 呼叫
    modifier ownerOnly() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 提供查詢當前價格
    function getPrice() public view returns (uint256) {
        return price;
    }

    // 提供查詢當前 txCounter 值
    function getTxCounter() public view returns (uint256) {
        return txCounter;
    }

    // 買入函式需傳入正確的 txCounter 值，藉此鎖定預期狀態，避免交易排序錯誤
    function buy(uint256 _txCounter) public returns (uint256) {
        // 固定重點: 檢查傳入的 _txCounter 是否和當前狀態相符
        require(_txCounter == txCounter, "Transaction ordering violation");
        emit Purchase(msg.sender, price);
        return price;
    }

    // 僅限 owner 更新價格，同時更新 txCounter 以改變狀態
    function setPrice(uint256 _price) public ownerOnly {
        price = _price;
        txCounter += 1;
        emit PriceChange(owner, price);
    }
}

// 攻擊合約用以展示修改後的保護效果
// 攻擊情境: 若攻擊者嘗試以錯誤的 txCounter 發送 buy 交易，將因 require 檢查失敗，
//         因此無法成功利用交易排序依賴漏洞。
contract AttackFixed {
    SolutionTransactionOrdering public target;

    // 部署時指定目標合約地址
    constructor(address _target) {
        target = SolutionTransactionOrdering(_target);
    }

    // 攻擊者嘗試使用不正確的 txCounter 值進行攻擊，將觸發 require 失敗
    function executeAttack(uint256 fakeTxCounter) public {
        // 當 owner 呼叫 setPrice 後，txCounter 會改變。
        // 若攻擊者無法獲得最新的 txCounter，則必須傳入錯誤的值，導致交易 revert，展示修正效果。
        target.buy(fakeTxCounter);
    }
}

/* 部署與測試步驟說明:
   1. 部署 SolutionTransactionOrdering 合約。
   2. 部署 AttackFixed 合約，並傳入 SolutionTransactionOrdering 合約的地址。
   3. 當 owner 呼叫 setPrice 更新價格時，txCounter 會同步變更。
   4. 攻擊者若未能正確取得最新的 txCounter 值，呼叫 executeAttack 時將因 require 檢查失敗，交易 revert，從而避免因交易排序錯誤遭到利用。
*/