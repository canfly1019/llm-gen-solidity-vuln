pragma solidity >=0.8.0;

// 修正後的合約將避免變數遮蔽 (shadowing) 問題，
// 將 deposit 函式的參數改名，避免與全域變數產生混淆。

contract Fixed {
    // 狀態變數，用來正確存放存款金額
    uint public balance;

    // deposit 函式中參數名稱修改為 amount 以避免 shadowing
    function deposit(uint amount) public payable {
        require(msg.value == amount, "Incorrect value");

        // 正確更新狀態變數 balance
        balance += msg.value;
    }

    function getBalance() public view returns(uint) {
        return balance;
    }
}

// 攻擊驗證合約，用來展示修正後合約不再存在漏洞。
contract AttackFixed {
    Fixed public fixedContract;

    // 部署時傳入 Fixed 合約的地址
    constructor(address _fixedContract) {
        fixedContract = Fixed(_fixedContract);
    }

    // 步驟：
    // 1. 部署 Fixed 合約。
    // 2. 部署 AttackFixed 合約並傳入 Fixed 合約地址。
    // 3. 呼叫 attack() 並附帶 Ether（例如 1 ether），確認存款後 balance 正確更新。
    function attack() public payable {
        fixedContract.deposit{value: msg.value}(msg.value);
    }
}
