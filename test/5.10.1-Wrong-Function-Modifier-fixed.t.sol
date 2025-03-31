pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The fixed contract with the corrected function modifier
contract C {
    // State variable x
    bytes public x = "012345678901234567890123456789";

    // Corrected: marked as external so that only external calls are allowed
    function test() external returns (uint) {
        // Simulate modifying data on external call
        x.push() = 0x01; // push byte 0x01
        x.push() = 0x02; // push byte 0x02
        return x.length;
    }
}

// A contract that calls C to simulate an external contract call flow
contract Caller {
    C public target;

    // The Caller is deployed with a target C contract address
    constructor(address _target) {
        target = C(_target);
    }

    // Calls the external function test() on contract C
    function callTest() public returns (uint) {
        uint len = target.test();
        return len;
    }
}


contract WrongFunctionModifierTest is Test {
    C public c;
    Caller public caller;

    function setUp() public {
        // Deploy the fixed contract C
        c = new C();
        // Deploy Caller with the address of the fixed contract
        caller = new Caller(address(c));
    }

    // Test: Direct external call to test() on contract C
    function testDirectExternalCall() public {
        // Check the initial length of x
        uint beforeLength = c.x().length; // Expected to be 30 bytes ("012345678901234567890123456789")
        
        // Call test() externally; this should add 2 bytes and return the new length
        uint ret = c.test();
        
        // Get the new state of x
        uint afterLength = c.x().length;
        
        // Verify that the returned length matches the new length of x
        assertEq(ret, beforeLength + 2, "Return length should be initial length + 2");
        assertEq(afterLength, beforeLength + 2, "State variable x should be updated correctly");
    }

    // Test: Call test() via the Caller contract, ensuring proper external invocation
    function testCallViaCaller() public {
        // Record the initial length of x
        uint beforeLength = c.x().length;
        
        // Caller contract calls test() externally on C
        uint ret = caller.callTest();
        
        // Get the updated length of x
        uint afterLength = c.x().length;
        
        // Confirm that the lengths match expectations
        assertEq(ret, beforeLength + 2, "Return length from callTest should be initial length + 2");
        assertEq(afterLength, beforeLength + 2, "x length should reflect the two new bytes added via test()");
    }

    // (Optional) Test to demonstrate that internal calls to external functions are not permitted directly.
    // Since external functions cannot be called internally without using 'this', this test reaffirms the modifier change.
    // Uncommenting the code below would cause a compilation error, verifying that internal calls are indeed not allowed.
    /*
    function testInternalCallNotAllowed() public {
        // The following direct call is not allowed and would not compile:
        // uint ret = c.test();

        // Instead, one must use an external call: uint ret = this.callTestInternal();
        
        // This test is left as documentation that only external calls are permitted.
    }
    */
}
