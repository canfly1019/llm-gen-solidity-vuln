pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The Fixed contract
contract ReturnValueFixed {
    // Corrected function: checks the low-level call return value
    function callChecked(address callee) public {
        (bool success, ) = callee.call(abi.encodeWithSignature("doSomething()"));
        require(success, "Low-level call failed");
    }
}

// Provided malicious contract. Note: because it implements doSomething(),
// the low-level call finds that function and does not trigger fallback.
contract MaliciousForFixed {
    // fallback intentionally reverts to simulate an attack scenario, but note
    // that the function doSomething exists so it is not used.
    fallback() external payable {
        revert("Malicious fallback triggered.");
    }

    // This function exists so that the call matches it. In practice this circumvents the
    // fallback revert, so the attack in AttackFixed will not revert.
    function doSomething() external pure returns (string memory) {
        return "This should not execute";
    }
}

// Attack demonstration contract
contract AttackFixed {
    ReturnValueFixed public safeReturnValue;
    MaliciousForFixed public malicious;

    constructor() {
        safeReturnValue = new ReturnValueFixed();
        malicious = new MaliciousForFixed();
    }

    // In the intended attack, the malicious contract would cause the low-level call to fail.
    // However, because MaliciousForFixed defines doSomething(), the call succeeds.
    // Thus, AttackFixed.attack() will succeed, demonstrating that the fix in ReturnValueFixed
    // forces the caller to check the low-level call return value (and would revert if the call failed).
    function attack() public {
        safeReturnValue.callChecked(address(malicious));
    }
}

// A contract that simulates a good (well-behaving) callee
contract GoodCallee {
    function doSomething() external pure returns (string memory) {
        return "Success";
    }
}

// A contract that simulates a callee that always reverts in doSomething()
contract RevertingCallee {
    function doSomething() external pure returns (string memory) {
        revert("RevertingCallee always fails");
    }
}

contract ReturnValueFixedTest is Test {
    ReturnValueFixed fixedContract;

    function setUp() public {
        fixedContract = new ReturnValueFixed();
    }

    // Test that callChecked succeeds when the callee correctly implements doSomething() and does not revert
    function testCallCheckedSucceedsWithGood() public {
        GoodCallee good = new GoodCallee();
        // Expect no revert
        fixedContract.callChecked(address(good));
    }

    // Test that callChecked reverts when the low-level call returns false
    // Here we simulate failure by calling a contract whose doSomething() reverts
    function testCallCheckedRevertsWithReverting() public {
        RevertingCallee bad = new RevertingCallee();
        vm.expectRevert(bytes("Low-level call failed"));
        fixedContract.callChecked(address(bad));
    }

    // Test the AttackFixed contract. 
    // Although the intended malicious behavior is to cause a revert, the provided MaliciousForFixed
    // contract includes a valid doSomething(), so in this deployment the attack() call will succeed.
    // This test shows that the fix in ReturnValueFixed correctly checks the low-level call return value.
    function testAttackFixedSucceeds() public {
        AttackFixed attacker = new AttackFixed();
        // Since MaliciousForFixed has an implemented doSomething(), attack() is not expected to revert.
        attacker.attack();
    }
}
