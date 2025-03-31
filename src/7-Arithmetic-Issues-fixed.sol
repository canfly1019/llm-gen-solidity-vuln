// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// 修正後的合約：透過 Solidity 0.8.0 內建的算術檢查，移除 unchecked 區塊以防止 overflow
// 同樣以 uint8 為示範，但在實際應用中建議使用 uint256 來儲存較大數據

contract ArithmeticIssuesFixed {
    uint8 public totalDeposits;
    mapping(address => uint8) public balances;
    uint8 public constant multiplier = 2;

    // deposit 函式利用內建 overflow 檢查，若超過則自動 revert
    function deposit(uint8 amount) external payable {
        totalDeposits += amount;
        balances[msg.sender] += amount;
    }

    // withdrawReward 函式計算正確的 reward
    function withdrawReward() external {
        uint8 userBalance = balances[msg.sender];
        // Solidity 0.8.0 的算術檢查可以避免 overflow
        uint8 reward = userBalance * multiplier + (totalDeposits - userBalance);
        payable(msg.sender).transfer(reward);
        balances[msg.sender] = 0;
    }
    
    // 正確接收 Ether 的 receive 函式
    receive() external payable {}
}

// 測試攻擊合約：嘗試使用與漏洞版本相同的攻擊手法，但由於內建算術檢查，將會 revert 並防止攻擊成功

contract TestAttackFixed {
    // 修改處：變數名稱從 fixed 更改為 fixedContract，以避免與 Solidity 保留字 (fixed point type) 衝突
    ArithmeticIssuesFixed public fixedContract; 

    // 因修正合約具有 payable fallback function，建構子參數必須為 address payable 或經過 payable 轉換
    constructor(address payable _fixedContract) {
        fixedContract = ArithmeticIssuesFixed(_fixedContract);
    }
    
    // 嘗試攻擊：使用 deposit(250) 及 deposit(10) 進行操作，但第二次 deposit 會因溢位檢查而 revert
    function tryAttack() public payable {
        fixedContract.deposit(250);
        fixedContract.deposit(10); // 此呼叫將 revert，攻擊失敗
    }
    
    receive() external payable {}
}
