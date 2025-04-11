pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/3.1-Improper-Gas-Requirements-Checking-fixed.sol";

contract FixedGasTest is Test {
    FixedRelayer public relayer;
    FixedTarget public target;
    FixedAttack public attackContract;

    function setUp() public {
        relayer = new FixedRelayer();
        target = new FixedTarget();
        attackContract = new FixedAttack(address(relayer), address(target));
    }

    // Test that relay call succeeds when a sufficient gasLimit is provided
    function testSuccessfulRelay() public {
        // Using the same gas limit as in the FixedAttack contract
        uint gasLimit = 300000;
        uint txIdBefore = relayer.transactionId();
        
        bool success = relayer.relay(address(target), "", gasLimit);
        
        // The call should succeed since gasLimit=300000 is sufficient for heavy computation
        assertTrue(success, "Relay call should succeed with sufficient gas");
        
        // Transaction record should be updated
        assertEq(relayer.transactionId(), txIdBefore + 1, "TransactionId should be incremented");
    }

    // Test that relay call fails with an insufficient gas limit
    function testInsufficientGasRelay() public {
        // Using a gasLimit that is intentionally too low
        uint gasLimit = 10000;
        uint txIdBefore = relayer.transactionId();
        
        bool success = relayer.relay(address(target), "", gasLimit);
        
        // The target requires that gasleft() >= _gasLimit, so this call should fail
        assertFalse(success, "Relay call should fail with insufficient gas");
        
        // Ensure that even though the call failed, the transaction record was marked as executed
        (bytes memory data, bool executed) = relayer.transactions(txIdBefore);
        assertTrue(executed, "Transaction record should be marked as executed even if call failed");
        
        // Verify the transaction counter was incremented
        assertEq(relayer.transactionId(), txIdBefore + 1, "TransactionId should be incremented");
    }

    // Test that the FixedAttack contract successfully calls attack()
    function testAttack() public {
        uint txIdBefore = relayer.transactionId();
        
        // The attack function uses a gasLimit of 300000 internally
        attackContract.attack();
        
        // Ensure that the relay call from the attack goes through and increments the transaction counter
        assertEq(relayer.transactionId(), txIdBefore + 1, "TransactionId should be incremented after attack");
    }
}
