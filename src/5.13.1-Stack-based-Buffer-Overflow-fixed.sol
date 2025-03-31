// Fixed Code with 修正後的遞迴呼叫
// 此版本已修正漏洞，將 a() 的遞迴呼叫改為呼叫 a2()，避免無限遞迴導致堆疊溢出。
// 此修正案例同時展示了一個簡單的攻擊例子（在攻擊合約中呼叫 b()），其效果已被修正。

pragma solidity >=0.8.0;

contract StackDepthTestFixed {
    // 建構子
    constructor() {}

    // a2 函式表示正確邏輯處理
    function a2() internal {
        // [示意其他正確邏輯的程式碼]
    }

    // 已修正：呼叫 a2() 代替 a() 内部無限遞迴呼叫
    function a() internal {
        a2();
    }

    // b() 函式外部呼叫入口
    function b() external {
        a();
    }
}

// 攻擊合約：儘管攻擊者依然呼叫 attack()，但修正後不會導致無限遞迴
contract AttackFixed {
    StackDepthTestFixed public target;

    // 部署時須提供目標合約位址
    constructor(address _targetAddress) {
        target = StackDepthTestFixed(_targetAddress);
    }

    // 攻擊示例：呼叫 b() 方法，但由於修正後邏輯已無遞迴漏洞，攻擊失效
    function attack() external {
        target.b();
    }
}

/*
補充說明：
1. 在修正過的程式碼中，a() 方法不再進行無限遞迴呼叫，雙重保護讓堆疊資源能夠正確使用。
2. 攻擊者透過 AttackFixed 合約呼叫 b() 仍會觸發內部流程，但不會使合約崩潰，進而避免出現安全風險。
3. 這個範例適用於所有 Solidity >=0.8.0 的版本，並不依賴於特定的第三方 Library。
*/