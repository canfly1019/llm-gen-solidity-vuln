pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// SPDX-License-Identifier: MIT

interface ICalled {
    function f() external;
}

// FixedContract as provided
contract FixedContract {
    uint public counter; // 狀態變數

    event Counter(uint counter);

    // 修正函式：
    // 先更新狀態並 emit 事件，再進行外部呼叫
    function bug(ICalled d) public {
        counter += 1;
        emit Counter(counter);
        d.f();
    }
}

// AttackerFixed as provided
contract AttackerFixed is ICalled {
    FixedContract public fixedContract;
    uint public attackCount;

    constructor(address _fixedContract) {
        fixedContract = FixedContract(_fixedContract);
    }

    function attack() public {
        fixedContract.bug(this);
    }

    function f() external override {
        if (attackCount < 2) {
            attackCount++;
            fixedContract.bug(this);
        }
    }
}

// A dummy contract implementing ICalled with a benign f() that does nothing
contract DummyCalled is ICalled {
    function f() external override {
        // Do nothing
    }
}

contract FixedContractTest is Test {
    FixedContract fixedContract;
    DummyCalled dummyCalled;
    AttackerFixed attackerFixed;

    function setUp() public {
        fixedContract = new FixedContract();
        dummyCalled = new DummyCalled();
        attackerFixed = new AttackerFixed(address(fixedContract));
    }

    // Test direct call to bug() with a dummy contract that does nothing.
    // This ensures that even a simple external call succeeds and the state is updated correctly.
    function testDirectBugCall() public {
        // Expectation: after one call, counter should be 1
        fixedContract.bug(ICalled(address(dummyCalled)));
        uint counterValue = fixedContract.counter();
        assertEq(counterValue, 1, "Counter should be incremented to 1");
    }

    // Test using AttackerFixed which attempts reentrancy
    function testNoUnexpectedReentrancyEffects() public {
        // Call attack, which will trigger a chain of bug() calls via reentrancy 
        // Expected chain:
        // 1st call: counter becomes 1
        // Reentrant call1 (attackCount from 0 to 1): counter becomes 2
        // Reentrant call2 (attackCount from 1 to 2): counter becomes 3
        // No further reentrancy because attackCount is now 2
        attackerFixed.attack();

        uint counterValue = fixedContract.counter();
        uint attackCountValue = attackerFixed.attackCount();

        // Validate that despite reentrancy attempts, counter increments only three times
        assertEq(counterValue, 3, "Counter should be 3 after reentrant calls");
        assertEq(attackCountValue, 2, "Attack count in attacker should be 2");
    }
}
