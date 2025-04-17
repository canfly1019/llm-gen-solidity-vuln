// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/3.1-Improper-Gas-Requirements-Checking-fixed.sol";

contract FixedGasTest is Test {
    FixedRelayer relayer;
    FixedTarget target;
    FixedAttack attacker;

    function setUp() public {
        relayer = new FixedRelayer();
        target = new FixedTarget();
        // Deploy attacker from a distinct address
        vm.prank(address(0xBEEF));
        attacker = new FixedAttack(address(relayer), address(target));
    }

    /// @notice Test that relay always returns false (call fails) for various gas limits
    function testRelayFailsForVariousGasLimits() public {
        uint[] memory gasLimits = new uint[](4);
        gasLimits[0] = 0;
        gasLimits[1] = 10_000;
        gasLimits[2] = 300_000;
        gasLimits[3] = 5_000_000;
        bytes memory data = hex"deadbeef";

        for (uint i = 0; i < gasLimits.length; i++) {
            // Call relay with differing gas budgets
            bool success = relayer.relay(address(target), data, gasLimits[i]);
            // In this fixed implementation, due to the gasleft() check and heavy loop,
            // the call will always fail (return false)
            assertFalse(success, "Relay should always fail due to gas check or out-of-gas");

            // Verify that the transaction record is created and marked executed
            (bytes memory recordedData, bool executed) = relayer.transactions(i);
            // recordedData should match the input data
            assertEq(keccak256(recordedData), keccak256(data), "Stored data mismatch");
            assertTrue(executed, "Transaction should be marked executed");
            // transactionId should increment by 1 each time
            assertEq(relayer.transactionId(), i + 1, "Incorrect transactionId after relay");
        }
    }

    /// @notice Test that the attacker cannot bypass the gas check, and relay state updates correctly
    function testAttackDoesNotBypassGasCheck() public {
        vm.startPrank(address(0xBEEF));
        // This will internally call relay with gasLimit = 300k, which still fails
        attacker.attack();
        vm.stopPrank();

        // The relay should have recorded one transaction
        assertEq(relayer.transactionId(), 1, "TransactionId should increment after attack");
        (, bool executed) = relayer.transactions(0);
        assertTrue(executed, "Transaction record should be marked executed after attack");
    }
}