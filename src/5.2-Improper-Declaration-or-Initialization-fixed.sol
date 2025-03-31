// SPDX-License-Identifier: UNLICENSED
// Fixed Code Example for Improper Declaration or Initialization 漏洞
// 修正方式一：使用 constructor 在部署時初始化 owner；
// 修正方式二：若必須使用 initialize()（例如 upgradeable 模式），則加入初始化檢查旗標。

pragma solidity >=0.8.0;

contract FixedContract {
    address public owner;
    bool private initialized; // 初始化旗標，避免重複呼叫 initialize

    // 若為可升級合約，可使用 initialize()，但需防止重入
    function initialize() public {
        require(!initialized, "Already initialized"); // 修正重點：檢查是否已初始化
        owner = msg.sender;
        initialized = true;
    }

    // 允許外部存款
    function deposit() public payable {}

    // 僅允許 owner 提款
    function withdraw() public {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }

    // 使用 receive 接收 Ether
    receive() external payable {}
}

// 測試固定版本是否能防止重複初始化
contract TestAttackFixed {
    FixedContract public fixedContract;

    // 修改 constructor 參數型別為 address payable 以符合 type conversion 要求
    constructor(address payable _fixedAddress) {
        fixedContract = FixedContract(_fixedAddress);
    }

    // 攻擊步驟示範：嘗試呼叫 initialize() 但應該會因為已初始化而 revert
    function attack() public {
        // 試圖重複初始化，預期會 revert
        fixedContract.initialize();
    }

    // 接收從 FixedContract 轉出的 Ether
    receive() external payable {}
}

/*
修正說明 (繁體中文):
1. 固定程式碼中，我們於 initialize() 加入了一個布林旗標 initialized，確保 initialize() 只能被呼叫一次，避免重複初始化的漏洞。
2. 或者，使用 constructor 於部署時就初始化 owner 可以從根本上解決此問題。
3. 另外，為符合 Solidity 轉型規則，在 Attack 與 TestAttackFixed 合約的 constructor 參數型別改為 address payable，
   確保地址轉型不會出現錯誤。
*/