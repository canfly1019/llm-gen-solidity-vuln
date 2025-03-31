// Solidity 版本標示為 >=0.8.0
// 此修正版本移除了 unchecked 區塊，利用 Solidity 0.8.0 版本內建的算術安全檢查，
// 並在減少 counter 時加入 require 檢查，以避免 underflow 漏洞發生。

pragma solidity >=0.8.0;

// 修正合約：FixedCounter
// 在這份修正後的程式碼中，所有數學運算均使用內建安全機制，
// 因此若有 overflow 或 underflow 的情況，將自動 revert，不再產生錯誤結果。
// 此外，我們在 decrement 函式中也加入 require 檢查，加強防護。
contract FixedCounter {
    uint256 public counter;

    // 安全增加 counter 的值：使用內建的安全算術，若 overflow 將自動 revert
    function increment(uint256 value) public {
        // 若溢位，內建檢查會導致交易 revert
        counter += value;
    }

    // 安全減少 counter 的值：先檢查是否可能造成 underflow，
    // 若 counter 不足以減去 value，則 revert
    function decrement(uint256 value) public {
        require(counter >= value, "Insufficient counter amount");
        counter -= value;
    }
}

// 攻擊合約測試：AttackFixed
// 使用相同的攻擊方式試圖觸發 underflow，但由於 FixedCounter 中有 require 檢查，
// 因此攻擊行為將會失敗並 revert。
// 攻擊測試流程：
// 1. 部署 FixedCounter 合約，counter 預設為 0。
// 2. 部署 AttackFixed 合約，並傳入 FixedCounter 合約地址。
// 3. 攻擊者呼叫 attack()，但因為 counter 為 0，所以 require 失敗，交易回退。
contract AttackFixed {
    FixedCounter public fixedCounter; // 修正變數名稱以避免與保留字衝突

    constructor(address _fixedCounter) {
        fixedCounter = FixedCounter(_fixedCounter);
    }

    // 試圖利用 underflow 進行攻擊，但由於 require 檢查條件不滿足，將會 revert
    function attack() public {
        fixedCounter.decrement(1);
    }
}
