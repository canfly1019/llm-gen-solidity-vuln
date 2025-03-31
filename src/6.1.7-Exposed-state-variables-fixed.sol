// Fixed contract: 修正後不允許外部修改 vulnerable 狀態
// Solidity 版本 pragma
pragma solidity >=0.8.0;

// 本修正版移除了可外部設定漏洞狀態的函式，且將狀態變數設為 private，
// 使得攻擊者無法任意改變條件，進而無法利用 exploit() 函式。
contract StatefulFixed {
    // 修正重點：將 vulnerable 設為 private，避免從外部直接查詢或修改
    bool private vulnerable = false;

    // constructor 中可以根據合約需求正確設定 vulnerable 狀態，此處預設為 false
    constructor() payable {}

    // exploit 函式保留，但只有在內部經過正確流程後才會讓 vulnerable 變為 true，
    // 此處我們不提供任何外部方法修改 vulnerable 狀態，避免漏洞利用
    function exploit(address payable attacker) public {
        require(vulnerable, "Error: Not authorized");
        attacker.transfer(address(this).balance);
    }

    // 如需依業務邏輯修改 vulnerable，必須透過安全的內部流程或管理者介入，本範例中不提供修改介面
    
    // 接收 Ether 的函數
    receive() external payable {}
}

// 攻擊測試合約：在修正後的合約中，由於無法從外部開啟漏洞，因此下列 attackFixed() 嘗試將失敗。
contract AttackFixed {
    StatefulFixed public fixedContract;

    // 部署時傳入目標修正後合約的位址
    constructor(StatefulFixed _fixedContract) payable {
        fixedContract = _fixedContract;
    }

    // 即使攻擊者嘗試呼叫 exploit()，由於 vulnerable 變數無法被外部改動，所以 require 會失敗
    function attack() public {
        fixedContract.exploit(payable(msg.sender));
    }

    // 接收 Ether
    receive() external payable {}
}
