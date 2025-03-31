pragma solidity >=0.8.0;
// SPDX-License-Identifier: MIT

// 修正後的合約版本，新增 newOwner 函數的 onlyOwner 限制，確保只有現有 owner 能新增其他 owner，從而避免攻擊者自行取得 owner 權限

contract MultiOwnable {
    // 使用 bool 來表示地址是否為 owner
    mapping(address => bool) public owners;

    // 在建構子中將部署者設為第一個 owner
    constructor() {
        owners[msg.sender] = true;
    }

    // onlyOwner modifier 要求呼叫者必須為 owner
    modifier onlyOwner() {
        require(owners[msg.sender], "Not owner");
        _;
    }

    // 修正版：newOwner 函數加上 onlyOwner 限制
    function newOwner(address _owner) external onlyOwner returns (bool) {
        require(_owner != address(0), "Invalid owner address");
        owners[_owner] = true;
        return true;
    }
}

contract TestContract is MultiOwnable {
    // withdrawAll 僅允許 owner 呼叫，正常情況下應只由合法的 owner 提取 Ether
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // 接收 Ether 的 receive 函數
    receive() external payable {}
}

// 攻擊示範合約 AttackFixed，示範即使攻擊者嘗試呼叫 newOwner 也會因權限不足而失敗

contract AttackFixed {
    TestContract public fixedContract;

    // 修改：將傳入的地址轉換為 payable，以符合類型要求
    constructor(address _fixedContract) {
        fixedContract = TestContract(payable(_fixedContract));
    }

    function attack() public {
        // 攻擊者嘗試呼叫 newOwner，但由於 caller 不是合法 owner，此呼叫會 revert
        fixedContract.newOwner(msg.sender);
        
        // 攻擊者再呼叫 withdrawAll，但因無 owner 權限，該呼叫也會失敗
        fixedContract.withdrawAll();
    }

    // 用於接收 Ether
    receive() external payable {}
}
