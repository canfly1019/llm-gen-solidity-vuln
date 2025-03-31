// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// 修正後的版本：此合約在部署時就固定 owner 為可信地址，並移除了會修改 owner 的 HT() 函式

// 簡化版 ERC20 代幣實作
contract ERC20 {
    mapping(address => uint256) public balances;
    uint256 public totalDistributed = 1000;

    // 模擬分發代幣功能
    function distr(address to, uint256 amount) public {
        balances[to] += amount;
    }
}

contract FixedHOTTO is ERC20 {
    // fix: 使用 private 限制 owner 資料變數，並在部署後即設定成固定可信地址
    address payable private owner = payable(0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB);

    // 修正: 移除重新指定 owner 的動作，僅執行分發操作
    function HT() public {
        distr(owner, totalDistributed);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT OWNER");
        _;
    }

    // 提款函式，只允許固定的 owner 呼叫
    function withdraw() public onlyOwner {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }

    // 允許合約接收 Ether
    receive() external payable {}
}

// 攻擊示範合約
// 攻擊者試圖利用 owner manipulation，但因為 owner 無法被竄改，提款操作將失敗
contract AttackerFixed {
    FixedHOTTO public target;

    // 修改: 依照 Solidity >=0.8.0 規範，使用 payable 轉換
    constructor(address _targetAddress) {
        target = FixedHOTTO(payable(_targetAddress));
    }

    // 攻擊步驟說明：
    // 1. 即使呼叫 target.HT()，也無法改變固定的 owner
    // 2. 呼叫 withdraw() 將失敗，因為呼叫者不是預先設定的 owner
    function attack() public {
        target.HT();
        target.withdraw();
    }

    // 接收 Ether
    receive() external payable {}
}

/*
說明：
1. FixedHOTTO 合約中，owner 在部署後即被固定為可信任地址，且無任何方式修改
2. 攻擊者部署 AttackerFixed 合約嘗試攻擊，但由於只有預先設定的 owner 可進行提款，
   因此提款將失敗。
3. 修改了 AttackerFixed 合約中 address 型態的轉換，以符合 Solidity >=0.8.0 的要求。
*/
