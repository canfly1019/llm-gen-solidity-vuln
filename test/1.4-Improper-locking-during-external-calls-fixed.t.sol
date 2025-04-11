pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/1.4-Improper-locking-during-external-calls-fixed.sol";

contract BidFixedTest is Test {
    BidFixed bidContract;
    AttackFixed attackContract;

    // We'll assume that the storage slot for the mapping pendingReturns is 3
    // since state (slot0), highestBidder (slot1), highestBid (slot2) come before it.
    // To compute the storage slot for pendingReturns[key], we use keccak256(abi.encode(key, uint256(3))).
    
    function setUp() public {
        // Deploy the BidFixed contract
        bidContract = new BidFixed();
        // Deploy the AttackFixed contract, passing BidFixed's address
        // Cast BidFixed address as payable
        attackContract = new AttackFixed(payable(address(bidContract)));

        // Fund the bidContract with sufficient ETH to cover withdrawals in our tests
        // Also fund the test contract and attackContract as needed
        vm.deal(address(bidContract), 10 ether);
        vm.deal(address(this), 10 ether);
        vm.deal(address(attackContract), 10 ether);
    }

    // Helper function to compute storage slot for pendingReturns mapping for a given address
    function _pendingReturnsSlot(address user) internal pure returns (bytes32 slot) {
        slot = keccak256(abi.encode(user, uint256(3)));
    }

    // Helper function to set pendingReturns via cheat code.
    function _setPendingReturn(address user, uint amount) internal {
        bytes32 slot = _pendingReturnsSlot(user);
        // Write the new value (amount as bytes32) into the slot of bidContract
        vm.store(address(bidContract), slot, bytes32(uint256(amount)));
    }

    // Test that withdraw fails if no pending funds are present
    function testWithdrawFailsWhenNoPendingFunds() public {
        // Make sure that pendingReturns for this address is 0
        uint pending = bidContract.pendingReturns(address(this));
        assertEq(pending, 0);

        // Expect revert due to no pending funds
        vm.expectRevert(bytes("No pending funds"));
        bidContract.withdraw();
    }

    // Test that a regular user with pending funds can withdraw successfully
    function testWithdrawSucceedsForRegularUser() public {
        // Use a test user different from this contract, e.g., userAddress
        address user = address(0xBEEF);
        uint amount = 1 ether;

        // Set pendingReturns for the user via cheat code
        _setPendingReturn(user, amount);
        // Confirm that the value is set
        uint stored = bidContract.pendingReturns(user);
        assertEq(stored, amount);

        // Make sure bidContract has enough ETH (already set in setUp, but double-check)
        assertGe(address(bidContract).balance, amount);

        // Record the balance of user before withdrawal
        uint userBalanceBefore = user.balance;

        // Withdraw as the user
        vm.prank(user);
        bidContract.withdraw();

        // After withdrawal, pendingReturns for the user should be 0
        uint storedAfter = bidContract.pendingReturns(user);
        assertEq(storedAfter, 0);

        // Check that user's balance increased by the withdrawn amount
        uint userBalanceAfter = user.balance;
        assertEq(userBalanceAfter, userBalanceBefore + amount);

        // Ensure that contract state is unlocked (i.e., state == F, which is represented as 0)
        assertEq(uint(bidContract.state()), 0);
    }

    // Test that if the attack contract attempts to withdraw funds, the external call reverts
    // and the contract state remains unlocked and pendingReturns is not consumed (transaction reverts)
    function testWithdrawRevertsForAttackContractAndStateRemainsUnlocked() public {
        // For the attack contract, we set a pending return of 1 ether
        uint amount = 1 ether;
        _setPendingReturn(address(attackContract), amount);
        uint stored = bidContract.pendingReturns(address(attackContract));
        assertEq(stored, amount);

        // Ensure bidContract has enough ETH
        assertGe(address(bidContract).balance, amount);

        // Expect the revert message from AttackFixed fallback
        vm.expectRevert(bytes("Attack contract rejects funds"));
        // Call attackWithdraw which will internally call bidContract.withdraw()
        // and trigger the external call that reverts
        vm.prank(address(attackContract));
        attackContract.attackWithdraw();

        // Since the transaction reverted, the state of bidContract should remain unchanged
        // pendingReturns for the attack contract should still be the original amount
        uint storedAfter = bidContract.pendingReturns(address(attackContract));
        assertEq(storedAfter, amount);

        // The contract state should also remain unlocked (State.F which is 0)
        assertEq(uint(bidContract.state()), 0);
    }
}
