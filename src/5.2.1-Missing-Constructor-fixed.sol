// SPDX-License-Identifier: MIT
// 修正說明：
// 使用正確的 constructor 初始化 owner，使得 owner 僅在部署期間被設定，並且無法被後續任意修改。
// 這樣一來，攻擊者將無法利用公開的初始化函式來重設 owner，以致於 withdraw() 只能由正確的 owner 呼叫。

pragma solidity >=0.8.0;

contract Missing {
    // 修正重點：在 constructor 中初始化 owner，避免任意呼叫函式重置權限
    address payable private owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyowner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 接收 ETH 的函式
    receive() external payable {}

    // withdraw 函式，僅允許 owner 呼叫，將合約內所有 ETH 轉給 owner
    function withdraw() public onlyowner {
        owner.transfer(address(this).balance);
    }
}

// 攻擊測試範例：
// 攻擊者將嘗試以通常的攻擊流程來變更 owner，
// 但由於修正後合約不包含公開可調用的初始化函式，因此攻擊嘗試將失敗。

contract AttackAttempt {
    Missing public target;

    // 將 _target 型別定為 address payable 以滿足型別轉換要求
    constructor(address payable _target) {
        target = Missing(_target);
    }

    // 攻擊步驟：
    // 嘗試呼叫不存在的初始化函式 initOwner()，但因為修正後合約中已移除此函式，因此該步驟無法成功，
    // 隨後呼叫 withdraw() 時，因為 msg.sender 非 owner 而導致交易失敗。
    function attack() external {
        // target.initOwner(); // 此函式已不存在，故無法修改 owner
        target.withdraw();
    }

    // 允許接收 ETH
    receive() external payable {}
}
