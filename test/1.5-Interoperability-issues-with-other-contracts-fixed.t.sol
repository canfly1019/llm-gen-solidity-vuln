pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Fixed Code Contracts from file 1.5-Interoperability-issues-with-other-contracts-fixed.sol

contract ConstantFixed {
    // State variable: counter
    uint public counter;

    // Function that modifies state
    function myFunction() public returns (uint) {
        counter++;
        return counter;
    }
}

contract NewContractFixed {
    function doSomething(address _addr) public returns (bool) {
        (bool success, ) = _addr.call(abi.encodeWithSignature("myFunction()"));
        require(success, "Call failed");
        return success;
    }
}

contract TestAttackFixed {
    NewContractFixed public target;
    ConstantFixed public constantContract;

    // Initialize with deployed addresses
    constructor(address _target, address _constant) {
        target = NewContractFixed(_target);
        constantContract = ConstantFixed(_constant);
    }

    // Call the target's doSomething and return the counter value
    function testCall() public returns (uint) {
        bool success = target.doSomething(address(constantContract));
        require(success, "Call to constantContract failed");
        return constantContract.counter();
    }
}

// Dummy contract to simulate a contract without myFunction (for revert testing)
contract DummyContract {
    // Does not implement myFunction, so call should fail
}


contract InteroperabilityFixedTest is Test {
    ConstantFixed constantContract;
    NewContractFixed newContract;
    TestAttackFixed attackContract;

    function setUp() public {
        // Deploy ConstantFixed contract
        constantContract = new ConstantFixed();
        // Deploy NewContractFixed contract
        newContract = new NewContractFixed();
        // Deploy TestAttackFixed passing the addresses of newContract and constantContract
        attackContract = new TestAttackFixed(address(newContract), address(constantContract));
    }

    function testCounterIncrement() public {
        // Initially counter should be 0
        uint initial = constantContract.counter();
        assertEq(initial, 0, "Counter should start at 0");

        // Call testCall once, should increment counter to 1
        uint newCounter = attackContract.testCall();
        assertEq(newCounter, 1, "Counter should be 1 after one call");

        // Call directly via NewContractFixed too, to confirm functionality across contracts
        bool success = newContract.doSomething(address(constantContract));
        assertTrue(success, "doSomething should return success");
        uint currentCounter = constantContract.counter();
        assertEq(currentCounter, 2, "Counter should be 2 after two calls");
    }

    function testRevertOnInvalidCall() public {
        // Deploy a dummy contract that does not implement myFunction so the call fails
        DummyContract dummy = new DummyContract();

        // Expect call to revert with "Call failed" when using invalid target
        vm.expectRevert(bytes("Call failed"));
        newContract.doSomething(address(dummy));
    }

    function testMultipleIncrementsThroughAttack() public {
        // Call testCall multiple times to ensure counter increments properly
        uint calls = 5;
        for (uint i = 0; i < calls; i++) {
            uint count = attackContract.testCall();
            assertEq(count, i + 1, "Counter did not increment properly via attackContract");
        }
    }
}
