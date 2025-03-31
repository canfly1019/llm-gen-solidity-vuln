pragma solidity >=0.8.0;

/*
  修正後的合約：FixedBank
  修正內容：
    移除了低階 call 呼叫外部合約函式的操作，在 withdraw 中直接處理提款流程，避免
    因為錯誤的函式呼叫使外部合約有機會透過實作特定函式而執行惡意操作。

  注意：
    即使合約中依然存在 payable fallback（receive）函式，由於 withdraw 直接完成提款，
    攻擊者無法再利用錯誤呼叫取得額外權限。
*/

contract FixedBank {
    mapping(address => uint256) public balances;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // 修正後的 withdraw 直接執行提款流程，不使用低階函式呼叫
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    // 如需額外邏輯，可考慮使用內部函式，但不直接對外呼叫以避免誤用
    function _performWithdraw(uint256 _amount) internal {
        // 正確的提款邏輯
    }

    receive() external payable {}
}

/*
  攻擊手法補充說明：
    在 FixedBank 中，攻擊者即使部署攻擊合約並實作 performWithdraw，也不會被觸發。
    此版本不再使用低階 call 呼叫特定函式，因此不存在先前版本的漏洞。
*/
