pragma solidity >=0.8.0;

// 此版本已修正變數名稱遮蔽問題，透過避免使用與狀態變數相同的名稱，確保權限檢查使用正確的變數。

contract BugFixed {
    // 狀態變數儲存合約擁有者，型別改為 address
    address public owner;

    // 在部署合約時，設定 owner 為部署者地址
    constructor() {
        owner = msg.sender;
    }

    // 修正後的 sensitive_function：
    // 原本如果要檢查合約擁有者，就不應該使用使用者傳入的參數來做比對。
    // 因此這裡移除了不必要的參數，直接使用狀態變數 owner 進行檢查。
    function sensitive_function() public {
        // 正確檢查：只有合約的 owner 能夠通過
        require(owner == msg.sender, "Not authorized");
        // ... 後續敏感操作
    }

    // alternate_sensitive_function 保持不變，因為局部變數命名不會與狀態變數衝突
    function alternate_sensitive_function() public {
        address localOwner = msg.sender;
        require(localOwner == msg.sender, "Not authorized");
        // ... 其他邏輯
    }
}

// 攻擊範例合約：
// 在修正後的版本中，sensitive_function 不再接受外部輸入的參數，
// 攻擊者如果嘗試呼叫 sensitive_function，將因為 require(owner == msg.sender) 檢查失敗（除非攻擊者正是 owner）。

contract AttackFixed {
    BugFixed public fixedBug;

    // 在部署 AttackFixed 時，傳入 BugFixed 合約的地址
    constructor(address _fixedBugAddress) {
        fixedBug = BugFixed(_fixedBugAddress);
    }

    // 攻擊流程：
    // 攻擊者試圖呼叫 sensitive_function，但由於檢查比對的是合約狀態變數 owner，
    // 攻擊者若非合約 owner，則呼叫將會 revert，從而無法進行後續敏感操作。
    function attack() public {
        fixedBug.sensitive_function();
    }
}
