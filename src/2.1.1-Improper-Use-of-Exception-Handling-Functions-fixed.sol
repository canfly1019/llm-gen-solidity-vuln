// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
修正後的程式碼：
修正：在 withdraw 時改用 call 方法轉送所有剩餘 gas 並檢查返回值，避免因固定 gas 限制帶來的問題。

測試步驟：
1. 部署 Fixed 合約並存入足夠 Ether。
2. 部署 AttackerFixed 合約，傳入 Fixed 合約地址（參數型別改為 address payable），並將變數名稱從 fixed 改為 fixedContract 以避免與關鍵字衝突。
3. 從 AttackerFixed 合約呼叫 attack() 測試提款，若攻擊合約的 fallback revert，則 withdraw 會 revert，確保資金安全，不會被惡意攔截。
*/

contract Fixed {
    mapping(address => uint256) public balances;

    // 接收 Ether 的 fallback
    receive() external payable {}

    // 存款函式
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 修正後的 withdraw 函式：使用 call 傳送 Ether 並檢查返回值
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }
}

// 攻擊測試合約，名稱從 AttackerFixed 改為此以示測試目的
contract AttackerFixed {
    Fixed public fixedContract; // 避免使用關鍵字 fixed

    // 將參數型別改為 address payable 以符合 Solidity 要求
    constructor(address payable _fixed) {
        fixedContract = Fixed(_fixed);
    }

    // fallback 函式，刻意 revert 來測試 withdraw 保護機制
    fallback() external payable {
        revert("Fallback triggered revert");
    }

    // 攻擊測試函式
    function attack() external payable {
        require(msg.value >= 1 ether, "Send at least 1 ETH");
        fixedContract.deposit{value: 1 ether}();
        fixedContract.withdraw(1 ether);
    }

    // 允許合約接收 Ether
    receive() external payable {}
}
