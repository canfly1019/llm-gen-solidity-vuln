// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.7.1-Unreachable-Payable-Function-fixed.sol";

contract LockedFixedTest is Test {
    LockedFixed locked;
    AttackLockedFixed attacker;

    function setUp() public {
        locked = new LockedFixed();
        attacker = new AttackLockedFixed();
        // Provide the attacker contract with some ether
        vm.deal(address(attacker), 10 ether);
        // Also ensure the test contract has some ether if needed
        vm.deal(address(this), 10 ether);
    }

    // Test that AttackLockedFixed fails to send Ether to LockedFixed
    function testAttackSendsEtherAndFails() public {
        uint256 amount = 1 ether;
        
        // Attempt to attack by sending 1 ether
        bool result = attacker.attack{value: amount}(payable(address(locked)));

        // The low-level call should return false because the fallback in LockedFixed reverts
        assertFalse(result, "Attack function should return false when sending Ether");

        // Verify that LockedFixed contract's balance is still 0
        uint256 balance = attacker.getTargetBalance(payable(address(locked)));
        assertEq(balance, 0, "LockedFixed's balance should be 0");
    }

    // Test that a direct transfer of Ether to LockedFixed reverts with the correct error message
    function testDirectTransferReverts() public {
        uint256 amount = 1 ether;

        // We expect the transaction to revert with the specific message
        vm.expectRevert(bytes("This contract does not accept Ether"));
        
        // Attempt direct transfer
        (bool success, ) = address(locked).call{value: amount}("");
        // If we reach here, the call did not revert, so we assert false
        require(!success, "Direct transfer should fail");
    }
}
