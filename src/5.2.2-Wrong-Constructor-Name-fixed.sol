// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// 修正後的合約：正確定義了建構子，避免攻擊者呼叫錯誤命名函數來竊取權限
contract Missing {
    // 狀態變數 owner
    address payable private owner;

    // Modifier 僅允許 owner 呼叫
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 正確使用 constructor 定義建構子，只有在合約部署時呼叫
    constructor() {
        owner = payable(msg.sender);
    }

    // 接收 Ether 的函數
    // 使用 receive() 處理僅轉入 Ether 的情形
    receive() external payable {}

    // 提款函數，只允許 owner 呼叫
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}

// 攻擊合約: 嘗試利用錯誤呼叫 constructor 來竊取合約 Ether，但此修正版本無此漏洞
contract Attack {
    Missing public fixedContract;

    // 修改參數類型為 address payable，以符合合約中 payable fallback 的定義
    constructor(address payable _fixedAddress) {
        fixedContract = Missing(_fixedAddress);
    }

    // 攻擊步驟說明：
    // 嘗試呼叫原本錯誤的 Constructor 函數將不會成功，因為修正後的合約已使用 constructor
    // 所以下列呼叫會失敗，從而防止攻擊者竊取 owner 權限。
    function attack() external {
        // 試圖呼叫不存在的 Constructor 函數會導致編譯錯誤或執行失敗
        // fixedContract.Constructor(); // 此行已移除或無法呼叫

        // 在此情況下，攻擊者無法竊取 owner 權限，因此 withdraw 也無法被呼叫。
    }

    // 接收 Ether
    receive() external payable {}
}
