// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the SafeCommandExecutor and SafeTarget contracts
// Assumes the contracts are in the ../src folder with the file name:
// 1.7.3-Unsafe-External-Command-Execution-fixed.sol

import "../src/1.7.3-Unsafe-External-Command-Execution-fixed.sol";

contract SafeCommandExecutorTest is Test {
    SafeCommandExecutor executor;
    SafeTarget target;
    address owner;
    address attacker = address(0xBEEF);

    function setUp() public {
        // deploy contracts; msg.sender is owner
        owner = address(this);
        executor = new SafeCommandExecutor();
        target = new SafeTarget();
    }

    // Test that execution of a whitelisted command succeeds and returns the correct result
    function testAllowedCommandExecution() public {
        // As owner, allow the safe command "doSomething"
        executor.allowCommand("doSomething");

        // Execute the command from a different (attacker) address
        vm.prank(attacker);
        bytes memory result = executor.executeCommand(address(target), "doSomething");

        // Decode the result assuming the function returns a string
        string memory output = abi.decode(result, (string));
        assertEq(output, "Safe function executed", "Whitelisted command did not execute properly");
    }

    // Test that any attempt to execute a non-whitelisted command is correctly prevented
    function testDisallowedCommandExecution() public {
        // Attempt to execute a command that is not whitelisted
        vm.prank(attacker);
        vm.expectRevert(bytes("Command not allowed"));
        executor.executeCommand(address(target), "nonAllowedCommand");
    }

    // Test that revoking a command prevents its further execution
    function testRevokeCommandPreventsExecution() public {
        // Owner allows the command and then revokes it
        executor.allowCommand("doSomething");
        executor.revokeCommand("doSomething");

        // Now, calling the command should revert because it is no longer allowed
        vm.prank(attacker);
        vm.expectRevert(bytes("Command not allowed"));
        executor.executeCommand(address(target), "doSomething");
    }
}
