pragma solidity >=0.8.0;
// SPDX-License-Identifier: UNLICENSED

// 修正後示例：修正重點在於更新 assert 條件，檢查 Lock 合約的餘額是否大於或等於原始傳入的數量，
// 避免因自毀強制轉入額外 ETH 而導致驗證失敗。

contract Lock {
    address public owner;
    uint256 public unlockTime;

    // 構造函式，接收 ETH 並設定擁有者及解鎖時間
    constructor(address _owner, uint256 _unlockTime) payable {
        owner = _owner;
        unlockTime = _unlockTime;
    }

    // 接收 Ether 的 fallback
    receive() external payable {}
}

contract LockContract {
    event Locked(address indexed owner, uint256 amount, Lock lockAddr, bytes edgewareAddr, bool isValidator, uint256 timestamp);

    modifier didStart() {
        // 假設合約操作已開始
        _;
    }

    modifier didNotEnd() {
        // 假設合約操作尚未結束
        _;
    }

    // 簡單函式：計算解鎖時間 (示例用途)
    function unlockTimeForTerm(uint256 term) public view returns (uint256) {
        return block.timestamp + term;
    }

    // 修正後的 lock 函式：更改 assert 條件，允許 Lock 合約餘額大於或等於 msg.value
    function lock(uint256 term, bytes calldata edgewareAddr, bool isValidator)
        external
        payable
        didStart
        didNotEnd
    {
        uint256 eth = msg.value;
        address owner = msg.sender;
        uint256 unlockTime = unlockTimeForTerm(term);
        
        // 建立 ETH 鎖定合約
        Lock lockAddr = (new Lock){value: eth}(owner, unlockTime);

        // 修正重點：驗證 Lock 合約餘額必須大於或等於原始傳入的 ETH，允許有額外 ETH
        assert(address(lockAddr).balance >= msg.value); // Fixed
        
        emit Locked(owner, eth, lockAddr, edgewareAddr, isValidator, block.timestamp);
    }
}

// 在修正後合約中，攻擊合約依然可利用 selfdestruct 強制轉入 ETH，但不會影響 assert 檢查
contract ForceSender {
    // ForceSend 的 constructor 標記為 payable 以允許傳入 ETH
    function attack(address payable target) external payable {
        ForceSend temp = new ForceSend{value: msg.value}();
        temp.kill(target);
    }
}

contract ForceSend {
    constructor() payable {}

    function kill(address payable target) public {
        selfdestruct(target);
    }
}

/*
使用範例 (測試流程說明):
1. 使用者呼叫 LockContract.lock 建立 Lock 合約，並傳入一定數量的 ETH，此時 Lock 合約餘額為 msg.value。
2. 若攻擊者呼叫 ForceSender.attack 嘗試透過 selfdestruct 傳入額外 ETH，由於修正後的 assert 條件修改為 >=，
   因此即使 Lock 合約餘額超過原始的 msg.value，assert 仍會通過，避免錯誤或狀態異常。
*/