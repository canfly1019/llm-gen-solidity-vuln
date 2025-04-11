pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/6.1.8-Wrong-Transaction-Definition-fixed.sol";

contract FixedContractTest is Test {
    FixedContract public fixedContract;
    AttackerFixed public attackerContract;
    address public attackerEOA = address(0xABCD);
    address public normalEOA = address(0x1234);

    function setUp() public {
        fixedContract = new FixedContract();
        attackerContract = new AttackerFixed();
    }
    
    // Test that when the attacker calls attack(), the execute() function records the deposit in pendingWithdrawals
    // instead of reverting the whole transaction
    function testAttackRecordsWithdrawal() public {
        uint deposit = 1 ether;
        // Fund attackerEOA
        vm.deal(attackerEOA, 10 ether);
        // The attackerEOA calls attack() via the attacker contract
        vm.prank(attackerEOA);
        attackerContract.attack{value: deposit}(address(fixedContract));

        // Check that total is updated
        assertEq(fixedContract.total(), deposit, "Total not updated correctly");
        // Since msg.sender in execute() is the attacker contract (not the externally owned attackerEOA),
        // the pending withdrawal is recorded for the attacker contract's address
        assertEq(fixedContract.pendingWithdrawals(address(attackerContract)), deposit, "Pending withdrawal not recorded correctly");
    }

    // Test that if the attacker attempts to withdraw the recorded funds, the withdraw() call fails
    // because the attacker's fallback in AttackerFixed always reverts.
    function testAttackWithdrawalFails() public {
        uint deposit = 1 ether;
        vm.deal(attackerEOA, 10 ether);
        vm.prank(attackerEOA);
        attackerContract.attack{value: deposit}(address(fixedContract));

        // Attempt withdrawal from the attacker contract's perspective
        vm.prank(address(attackerContract));
        vm.expectRevert(bytes("Withdrawal failed"));
        fixedContract.withdraw();

        // As the withdraw() call reverts after setting pendingWithdrawals to 0,
        // the state change is reverted. Thus, pending withdrawals should remain recorded.
        assertEq(fixedContract.pendingWithdrawals(address(attackerContract)), deposit, "Pending withdrawal should remain after failed withdrawal attempt");
    }

    // Test that a normal user (without a reverting fallback) can successfully complete the execute() call
    // without causing funds to be locked in pendingWithdrawals.
    function testNormalUserExecute() public {
        uint deposit = 1 ether;
        vm.deal(normalEOA, 10 ether);
        vm.prank(normalEOA);
        fixedContract.execute{value: deposit}();

        // For a normal EOA, the inline call transferring Ether should succeed, leaving pendingWithdrawals at 0
        assertEq(fixedContract.total(), deposit, "Total not updated correctly for normal user");
        assertEq(fixedContract.pendingWithdrawals(normalEOA), 0, "There should be no pending withdrawal for normal user");
    }
}
