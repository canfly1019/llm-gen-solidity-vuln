pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the FixedContract and AttackContractFixed from the provided file
import "../src/1.3-Improper-Check-of-External-Call-Result-fixed.sol";

contract FixedContractTest is Test {
    FixedContract fixedContract;
    AttackContractFixed attackContract;

    // Use a distinct address for simulating attacks
    address attacker = address(0xBEEF);

    function setUp() public {
        fixedContract = new FixedContract();
        // Deploy the attack contract, pointing it to the FixedContract
        attackContract = new AttackContractFixed(payable(address(fixedContract)));

        // Fund the attacker address with ether so that it can send deposit transactions
        vm.deal(attacker, 10 ether);
        
        // Have the attacker deposit 1 ether via the AttackContract to FixedContract
        vm.prank(attacker);
        attackContract.deposit{value: 1 ether}();
    }

    // Test that an attack contract that reverts on receiving ETH (via fallback) will cause the withdraw to revert
    function testAttackWithdrawReverts() public {
        // Confirm that the deposit was recorded
        assertEq(fixedContract.balances(address(attackContract)), 1 ether);

        // When the attack contract initiates a withdrawal, the fallback reverts and the external call fails.
        // Expect the FixedContract withdraw call to revert with the proper error message.
        vm.expectRevert("External call failed");
        vm.prank(attacker);
        attackContract.attackWithdraw(1 ether);

        // Ensure the balance mapping remains unaffected since the whole transaction should have reverted
        assertEq(fixedContract.balances(address(attackContract)), 1 ether);
    }

    // Test normal functionality with an external owned address (which does not have a reverting fallback)
    function testNormalUserWithdraw() public {
        // Use a simple EOA that doesn't revert on receiving ether
        address user = address(0xCAFE);
        vm.deal(user, 5 ether);

        // Have the user deposit 1 ether
        vm.prank(user);
        fixedContract.deposit{value: 1 ether}();
        assertEq(fixedContract.balances(user), 1 ether);

        // The user attempts to withdraw, and it should succeed since EOAs can receive ether without triggering fallback reverts
        vm.prank(user);
        fixedContract.withdraw(1 ether);

        // Verify that the balance mapping for the user has been updated correctly
        assertEq(fixedContract.balances(user), 0);
        
        // Optionally, check the user's balance increased by ~1 ether (accounting for gas costs)
        // We use an inequality check as gas costs make an exact match hard to predict
        assertGt(user.balance, 1 ether);
    }
}
