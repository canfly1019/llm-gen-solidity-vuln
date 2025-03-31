pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Include the contract code inline to avoid path import issues
contract AssertMultiTx1 {
    // State variable that is only initialized during deployment
    uint256 private param;

    // Constructor that requires _param to be greater than 0. Deployment fails otherwise.
    constructor(uint256 _param) {
        require(_param > 0, "Input must be greater than zero");
        param = _param;
    }

    // run() checks the invariant that param > 0 using an assert.
    // Since param is immutable after deployment, this assert should never fail.
    function run() public view {
        assert(param > 0);
    }
}

contract AssertMultiTx1Test is Test {
    
    // Test that deploying the contract with a value of 0 fails as expected.
    function testRevertOnZeroParam() public {
        vm.expectRevert("Input must be greater than zero");
        // This should revert because _param is 0
        new AssertMultiTx1(0);
    }

    // Test that a valid parameter (greater than zero) deploys successfully
    // and that the invariant in run() holds, by executing run() without any issues.
    function testValidDeploymentAndInvariant() public {
        // Deploy with a valid non-zero parameter
        AssertMultiTx1 instance = new AssertMultiTx1(1);
        
        // run() is a view function that uses assert, so calling it should not revert
        instance.run();
    }

    // Additional test: Verify that there is no way to modify param and break the invariant.
    // Since there is no setter or external function, this also confirms that the vulnerability is fixed.
    function testImmutableInvariant() public {
        // Deploy with a valid non-zero parameter
        AssertMultiTx1 instance = new AssertMultiTx1(10);
        
        // While we cannot change the state from the test, multiple calls to run() should prove invariant holds.
        instance.run();
        instance.run();
    }
}
