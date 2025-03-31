pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// ------------ Contract Under Test ------------

// Fixed Code with 修正後的遞迴呼叫
// 此版本已修正漏洞，將 a() 的遞迴呼叫改為呼叫 a2()，避免無限遞迴導致堆疊溢出。
// 此修正案例同時展示了一個簡單的攻擊例子（在攻擊合約中呼叫 b()），其效果已被修正。

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

// ------------ Foundry Test Contract ------------

contract StackDepthTestFixedTest is Test {
    StackDepthTestFixed target;
    AttackFixed attacker;

    function setUp() public {
        // Deploy the target contract
        target = new StackDepthTestFixed();
        // Deploy the attacking contract with target address
        attacker = new AttackFixed(address(target));
    }

    // Test that a direct call to b() succeeds without causing stack overflow or reverting
    function testDirectCallB() public {
        // It should complete successfully since the recursion has been fixed
        target.b();
        // No assertions here because the absence of a revert indicates success
    }

    // Test that an attack using the AttackFixed contract does not cause a stack overflow
    function testAttackCall() public {
        // Even though the attack contract calls b(), the fixed logic prevents any stack overflow
        attacker.attack();
        // If the call completes, the vulnerability has been mitigated
    }

    // Test that multiple calls do not accumulate risk of stack overflow
    function testMultipleCalls() public {
        // Execute multiple calls to b() via both direct and attack contract
        for (uint256 i = 0; i < 10; i++) {
            target.b();
            attacker.attack();
        }
    }
}
