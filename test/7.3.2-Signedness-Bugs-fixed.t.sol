pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/7.3.2-Signedness-Bugs-fixed.sol";

contract FixedWithdrawTest is Test {
    FixedWithdraw fixedContract;

    // Setup: deploy the FixedWithdraw contract and fund it with 2 ether
    function setUp() public {
        fixedContract = new FixedWithdraw();
        vm.deal(address(fixedContract), 2 ether);
    }

    // Test a valid withdrawal from a normal externally owned account (non-precompiled address)
    function testValidWithdraw() public {
        // Use an EOA that is not a precompile address (avoid 0x1, etc.)
        address user = vm.addr(100);
        vm.deal(user, 0 ether);
        
        // Call withdrawOnce for 0.5 ether as the user
        vm.prank(user);
        fixedContract.withdrawOnce(0.5 ether);
        
        // Check that the user's withdrawn flag is set
        bool withdrawn = fixedContract.transferred(user);
        assertTrue(withdrawn, "User's withdrawal flag should be true");
        
        // Verify that the user received 0.5 ether
        assertEq(user.balance, 0.5 ether, "User should receive 0.5 ether");
        
        // Verify contract balance decreased appropriately
        assertEq(address(fixedContract).balance, 2 ether - 0.5 ether, "Contract balance should decrease by 0.5 ether");
    }

    // Test that withdrawing more than 1 ether is not allowed
    function testExceedLimit() public {
        address user = vm.addr(101);
        vm.prank(user);
        vm.expectRevert("Amount exceeds limit");
        fixedContract.withdrawOnce(1 ether + 1);
    }

    // Test that a second withdrawal from the same address reverts
    function testAlreadyWithdrawn() public {
        address user = vm.addr(102);
        vm.deal(user, 0 ether);
        
        // First withdrawal succeeds
        vm.prank(user);
        fixedContract.withdrawOnce(0.5 ether);
        
        // Second withdrawal should fail
        vm.prank(user);
        vm.expectRevert("Already withdrawn");
        fixedContract.withdrawOnce(0.5 ether);
    }

    // Test simulating negative value conversion
    // Attempting to withdraw an amount representing a negative signed int if mis-converted
    // Here we use type(uint256).max which is far above 1 ether and should revert
    function testSimulatedNegativeValueConversion() public {
        address user = vm.addr(103);
        vm.prank(user);
        vm.expectRevert("Amount exceeds limit");
        fixedContract.withdrawOnce(type(uint256).max);
    }

    // Test the AttackFixed contract to simulate an attacker trying to abuse the system
    function testAttackContract() public {
        address attackerEOA = vm.addr(104);
        vm.deal(attackerEOA, 0 ether);
        
        // Deploy the AttackFixed contract as the attacker
        vm.startPrank(attackerEOA);
        AttackFixed attack = new AttackFixed(payable(address(fixedContract)));
        attack.attack();
        vm.stopPrank();
        
        // Verify that the attack contract received 0.5 ether
        assertEq(address(attack).balance, 0.5 ether, "Attack contract should have received 0.5 ether");
        
        // Attempting a second attack should revert due to already withdrawn flag
        vm.prank(attackerEOA);
        vm.expectRevert("Already withdrawn");
        attack.attack();
    }
}
