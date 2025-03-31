pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The contract Fixed is provided in the vulnerable context but has been fixed
contract Fixed {
    // Only three slots for the buffer array
    bytes32[3] public buffer;
    uint256 public secret;  // Stored in slot 3

    constructor() {
        // Initialize buffer with keccak256 values
        buffer[0] = keccak256(abi.encodePacked("A"));
        buffer[1] = keccak256(abi.encodePacked("B"));
        buffer[2] = keccak256(abi.encodePacked("C"));
        secret = 999;
    }

    // ReadAt only allows indices within 0 to buffer.length-1
    function readAt(uint256 index) public view returns (bytes32) {
        require(index < buffer.length, "index out of bound");
        return buffer[index];
    }
}


contract FixedTest is Test {
    Fixed fixedContract;

    function setUp() public {
        fixedContract = new Fixed();
    }

    // Test valid buffer accesses to ensure that the intended data is correctly returned
    function testValidAccess() public {
        // Expected values
        bytes32 expected0 = keccak256(abi.encodePacked("A"));
        bytes32 expected1 = keccak256(abi.encodePacked("B"));
        bytes32 expected2 = keccak256(abi.encodePacked("C"));

        // Actual values from contract
        bytes32 result0 = fixedContract.readAt(0);
        bytes32 result1 = fixedContract.readAt(1);
        bytes32 result2 = fixedContract.readAt(2);

        assertEq(result0, expected0, "Invalid result for index 0");
        assertEq(result1, expected1, "Invalid result for index 1");
        assertEq(result2, expected2, "Invalid result for index 2");
    }

    // Test that accessing an out of bounds index (overflow scenario) reverts
    function testInvalidAccess() public {
        vm.expectRevert("index out of bound");
        fixedContract.readAt(3);
    }

    // Test with a very large index to simulate potential overflow/underflow scenarios
    function testInvalidAccessWithMaxUint() public {
        vm.expectRevert("index out of bound");
        fixedContract.readAt(type(uint256).max);
    }
}
