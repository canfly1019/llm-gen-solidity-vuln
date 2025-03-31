// SPDX-License-Identifier: UNLICENSED
// Solidity code 修正 Improper Access Control 漏洞
// 修正描述: 修正版本中限制了只有 owner 才能呼叫 changeOwner() 與 withdraw()，避免未授權存取。

pragma solidity >=0.8.0;

contract FixedAccess {
    // 狀態變數：限制權限之 owner
    address public owner;
    uint public funds;
    
    // 權限檢查修飾子：僅允許 owner 呼叫
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // 建構子：設定部署者為 owner
    constructor() {
        owner = msg.sender;
    }
    
    // 函式：變更 owner，只允許當前 owner 執行
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    // 函式：僅限 owner 提取合約金額
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    // 接收 Ether 功能
    receive() external payable {
        funds += msg.value;
    }
}

// 攻擊測試合約：用來模擬惡意使用者的攻擊行為
// 注意：由於 FixedAccess 具有 payable fallback function，在 AttackFixed 合約中，
// 建構子參數應為 address payable，以避免明確型別轉換錯誤
contract AttackFixed {
    FixedAccess public fixedContract;

    // 將參數型態修改為 address payable
    constructor(address payable _fixedAddress) {
        fixedContract = FixedAccess(_fixedAddress);
    }
    
    // 攻擊模擬：嘗試呼叫 changeOwner 與 withdraw
    // 預期結果：因為權限檢查失敗，因此攻擊者無法成功執行這些函式
    function attack() public {
        // 嘗試變更 owner，應該會 revert
        fixedContract.changeOwner(msg.sender);
        
        // 嘗試提取合約所有資金，應該會 revert
        fixedContract.withdraw();
    }

    // 接收 Ether
    receive() external payable {}
}
