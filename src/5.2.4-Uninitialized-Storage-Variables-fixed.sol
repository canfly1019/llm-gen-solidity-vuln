pragma solidity >=0.8.0;

// 修正版：修正 Uninitialized Storage Variables 漏洞
// 說明：在 TransferMoney 函式中，改用 memory 初始化 newTransfer，
// 避免直接操作 storage 的 slot 0，從而保護 unlocked 變數不被覆蓋。

contract PaySupplierFixed {
    bool public unlocked = false; // 儲存在 slot 0

    struct Person {
        bytes32 name;
        // 其他欄位可加入
    }

    // 改用 memory 初始化 newTransfer，不會影響 storage 中的資料
    function TransferMoney(bytes32 _name) public {
        Person memory newTransfer; // 正確使用 memory
        newTransfer.name = _name;
        // 由於 newTransfer 僅存在記憶體中，unlocked 不會被改寫
        require(unlocked, "unlocked is false");
    }

    // 可接收 Ether 的 fallback 函式
    receive() external payable {}
}

// 攻擊合約：試圖利用漏洞但失敗，因為修正版並未操作到 unlocked
contract AttackPaySupplierFixed {
    PaySupplierFixed public target;

    constructor(PaySupplierFixed _target) {
        target = _target;
    }

    // 攻擊流程：
    // 即使傳入相同的攻擊參數 bytes32(uint256(1))，
    // newTransfer 被正確初始化於 memory，
    // 因此 unlocked 仍保持初始狀態（false），攻擊無法通過 require 檢查。
    function attack() public {
        target.TransferMoney(bytes32(uint256(1)));
    }
}
