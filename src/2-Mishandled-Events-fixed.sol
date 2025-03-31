// SPDX-License-Identifier: UNLICENSED
// Solidity >=0.8.0
// 修正後的合約，將 withdraw 函式中的 assert 替換為 require，
// 這樣在檢查失敗時，所有先前改變的狀態會回滾，並同時退回所有剩餘 gas，
// 同時也可傳回自訂的錯誤訊息，方便使用者及開發者釐清原因。

pragma solidity >=0.8.0;

contract FixedContract {
    // 狀態變數，紀錄各地址存款餘額
    mapping(address => uint256) public balances;

    // 事件記錄
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    // 存款函式
    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // 提領函式：修正後使用 require 來檢查餘額，避免消耗所有剩餘 gas
    function withdraw(uint256 _amount) public {
        // 修正重點：使用 require 並傳回錯誤訊息，
        // 當條件不成立時，所有執行的改變皆會回滾，同時退款所有剩餘 gas。
        require(balances[msg.sender] >= _amount, "Insufficient Balance");
        
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }

    // 正確實作接收 Ether 的函式
    receive() external payable {
        deposit();
    }
}

// 測試攻擊合約（與漏洞版本相同的攻擊合約，但攻擊效果已被修正合約抵消）:
// 說明：即使攻擊者嘗試呼叫 withdraw 並要求超額提領，require 會回傳錯誤訊息而不會消耗所有剩餘 gas。

contract AttackFixed {
    FixedContract public target;

    // 修改：使用 payable address 進行顯式轉換以滿足編譯要求
    constructor(address _target) {
        target = FixedContract(payable(_target));
    }

    // 攻擊示範函式：試圖呼叫 withdraw 但由於條件檢查使用 require，
    // 當提領金額超出餘額時會直接回退，並附上錯誤訊息 'Insufficient Balance'
    function attack() public {
        target.withdraw(1 ether);
    }
}

/*
部署與測試步驟（修正後的合約）：
1. 部署 FixedContract 合約。
2. 部署 AttackFixed 合約，並將 FixedContract 的地址傳入 AttackFixed 的 constructor。
3. 呼叫 AttackFixed 合約的 attack() 函式，因為提領條件不成立，合約會 revert 並回傳 'Insufficient Balance'，
   攻擊者不會造成全部 gas 的消耗，此攻擊方式已被修正。
*/