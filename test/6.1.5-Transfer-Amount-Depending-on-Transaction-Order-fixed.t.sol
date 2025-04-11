pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/6.1.5-Transfer-Amount-Depending-on-Transaction-Order-fixed.sol";

// This test contract focuses on the transaction ordering vulnerability fix.
// It tests that the contract only executes the transfer when the recipient's action (order == 2) is recorded,
// and rejects transfers if the wrong order is present.

contract AmountSenderFixedTest is Test {
    AmountSenderFixed target;
    AttackFixed attack;

    // Allow this contract to receive Ether so that transfers can succeed.
    receive() external payable {}

    function setUp() public {
        // Deploy the target contract
        target = new AmountSenderFixed();

        // Provide the target contract with enough Ether so that it can transfer funds
        vm.deal(address(target), 10 ether);

        // Deploy the attack contract with a reference to the target
        attack = new AttackFixed(payable(address(target)));
    }

    // Test that with correct ordering (provider then recipient), the transfer succeeds
    function testCorrectOrderTransfer() public {
        // Provider sets a high amount (this operation sets order = 1)
        target.setAmountOp2(1000);
        
        // Recipient sets the actual transfer value (order becomes 2) and overrides the amount to 1
        target.setAmountOp1(1);

        // Record balance before the transfer
        uint balanceBefore = address(this).balance;
        
        // Execute the transfer. This call should succeed because order == 2.
        target.setTransferAmount();

        // Check that exactly 1 wei was transferred to this contract
        uint balanceAfter = address(this).balance;
        assertEq(balanceAfter - balanceBefore, 1, "Recipient should receive exactly 1 wei");
    }

    // Test that using the wrong operation order (only provider action) results in a revert
    function testRevertWithWrongOrder() public {
        // Only provider operation is performed, so order remains 1
        target.setAmountOp2(1000);

        // Expect the transfer to revert because the order is not set to 2 (recipient didn't act)
        vm.expectRevert(bytes("Operation order error"));
        target.setTransferAmount();
    }

    // Test the attack contract execution
    // The AttackFixed contract mimics an attack flow by calling the functions in sequence:
    // 1. provider sets a high amount
    // 2. recipient sets a low amount resetting order to 2
    // Thus, a correct transfer of exactly 1 wei should occur
    function testAttackFixedExecution() public {
        // Record the AttackFixed contract's balance before executing the attack
        uint balanceBefore = address(attack).balance;

        // Execute attack routine
        attack.executeAttack();

        // After execution, the AttackFixed should have received exactly 1 wei
        uint balanceAfter = address(attack).balance;
        assertEq(balanceAfter - balanceBefore, 1, "Attack contract should receive exactly 1 wei");
    }
}
