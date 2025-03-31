// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
修正後的合約 FixedContract 解決了原始漏洞。
主要修改內容：
1. withdraw 函式中的身份檢查改為使用 msg.sender，
   僅允許 owner 自行提領資金，避免透過中介合約進行釣魚攻擊。
2. AttackContract 部分同樣修改為接受 address payable 的參數，符合 Solidity >=0.8.0 的要求。

修正後的攻擊流程說明：
即使攻擊者藉由攻擊合約轉呼叫 withdraw()，最終 msg.sender 仍然是攻擊合約而非 owner，
故無法通過身份驗證，資金可得到良好保護。
*/

contract FixedContract {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender; // 初始化 owner 為合約部署者
    }

    // 修正後的 withdraw 函式：檢查 msg.sender 是否為 owner
    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "Not authorized"); // 僅允許 owner 提款
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // 接收 Ether 的 receive 函式，將收到的款項累計到 msg.sender 的餘額中
    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}

// 攻擊合約示意，但由於 FixedContract 使用 msg.sender 進行檢查，即使透過 AttackContract 呼叫 withdraw() 也不會成功
// 注意：參數 _target 已修改為 address payable 以符合 Solidity >=0.8.0 的顯式轉換要求。
contract AttackContractFixed {
    FixedContract public target;

    constructor(address payable _target) {
        target = FixedContract(_target);
    }

    function attack() public {
        target.withdraw(1 ether);
    }

    receive() external payable {}
}
