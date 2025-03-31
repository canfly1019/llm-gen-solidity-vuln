pragma solidity >=0.8.0;

// FixedBank合約修正了Incorrect Sequencing of Behavior漏洞，
// 透過在呼叫外部合約傳送Ether之前先更新內部狀態，避免重入攻擊。

contract FixedBank {
    // 狀態變數：使用mapping來追蹤每個地址的餘額
    mapping(address => uint) public balances;

    // deposit函式無漏洞，可讓使用者存款
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // withdraw函式已修正：先更新狀態，後呼叫外部地址發送Ether
    function withdraw(uint amount) external {
        require(balances[msg.sender] >= amount, "Insufficient funds");
        // 先更新狀態，避免reentrancy攻擊
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    fallback() external payable {}
    receive() external payable {}
}

// 即使攻擊者合約重新部署類似AttackerFixed合約，其攻擊嘗試也會失敗，
// 因為FixedBank在進行提款操作前已先更新使用者的餘額。

contract AttackerFixed {
    FixedBank public fixedBank;
    address public owner;
    uint public attackAmount = 1 ether;

    constructor(FixedBank _fixedBank) {
        fixedBank = _fixedBank;
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value == attackAmount, "Need exact attack amount");
        fixedBank.deposit{value: msg.value}();
    }

    function attack() external {
        fixedBank.withdraw(attackAmount);
    }

    // 攻擊者嘗試重入，但由於狀態已更新，無法成功重新提款
    fallback() external payable {}

    function collectEther() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}

/*
部署與測試流程說明 (繁體中文)：
1. 部署FixedBank合約。
2. 攻擊者部署AttackerFixed合約，並在建構子中傳入FixedBank合約地址。
3. 攻擊者呼叫AttackerFixed.deposit()存入1 ether。
4. 攻擊者呼叫AttackerFixed.attack()嘗試觸發withdraw。
5. 由於FixedBank在提款前先更新狀態，攻擊者的重入攻擊將失敗，
   固定提款操作只會傳送一次正確的金額，不會重複提款。
*/
