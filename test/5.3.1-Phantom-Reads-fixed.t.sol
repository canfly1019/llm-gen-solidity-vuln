// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the target contract. In Foundry you might use the appropriate import path.

contract FixedPhantom {
    // State variable: record values stored in an array
    uint256[] public records;

    // Public function to add a record
    function addRecord(uint256 value) public {
        records.push(value);
    }

    // Atomically process records, reading and computing a sum in one function call
    function processRecords() public view returns (uint256 sum) {
        uint256 length = records.length;
        for (uint256 i = 0; i < length; i++) {
            sum += records[i];
        }
        return sum;
    }
}

contract FixedPhantomTest is Test {
    FixedPhantom fixedPhantom;

    function setUp() public {
        fixedPhantom = new FixedPhantom();
    }

    // Test 1: When no records have been added, processRecords should return 0
    function testEmptyRecordsSum() public {
        uint256 sum = fixedPhantom.processRecords();
        assertEq(sum, 0, "Sum should be 0 when no records are present");
    }

    // Test 2: Sum remains consistent in a single call even if state updates happen in subsequent transactions
    function testProcessRecordsConsistent() public {
        // Add records in one transaction
        fixedPhantom.addRecord(10);
        fixedPhantom.addRecord(20);
        fixedPhantom.addRecord(30);

        // Call processRecords, expecting the sum to be the sum of all added records
        uint256 sum = fixedPhantom.processRecords();
        assertEq(sum, 60, "Expected sum of records is 60");

        // Now, in a separate transaction (simulated by the next call), add another record and check that processRecords gets updated
        fixedPhantom.addRecord(40);

        uint256 newSum = fixedPhantom.processRecords();
        assertEq(newSum, 100, "Expected sum of records after adding 40 is 100");
    }

    // Test 3: Simulate same-block concurrent transactions scenario
    // Although Ethereum executes transactions sequentially, this test ensures that the atomic nature of processRecords
    // prevents phantom reads. We simulate by calling processRecords before and after state change within the same block
    function testAtomicSnapshotConsistency() public {
        // For the purpose of this test, we simulate transactions that occur in the same block by manually setting the block number.
        // Add initial records
        fixedPhantom.addRecord(5);
        fixedPhantom.addRecord(15);
        
        // Capture sum in the current state
        uint256 initialSum = fixedPhantom.processRecords();
        assertEq(initialSum, 20, "Initial sum should be 20");

        // Simulate two transactions in the same block: one transaction calling processRecords and another adding a record.
        // Note: In reality, each transaction is atomic. Here we simulate by not rolling the block number between actions.
        uint256 sumBefore = fixedPhantom.processRecords();
        // Now add a record; even though this state change is immediate, it will be seen in subsequent transactions.
        fixedPhantom.addRecord(30);
        uint256 sumAfter = fixedPhantom.processRecords();

        // The call made before the addRecord in this test (sumBefore) is not retroactively affected.
        // The second call (sumAfter) reflects the updated state. This simulates consistent reading in a single atomic call.
        assertEq(sumBefore, 20, "Sum before adding new record should be 20");
        assertEq(sumAfter, 50, "Sum after adding new record should be 50");
    }

    // Test 4: Ensure that multiple adds during simulated concurrent interactions do not lead to unexpected computed sums.
    function testMultipleConcurrentInteractions() public {
        // Add several records
        for (uint256 i = 1; i <= 5; i++) {
            fixedPhantom.addRecord(i * 10); // 10, 20, 30, 40, 50
        }

        uint256 sumInitial = fixedPhantom.processRecords();
        assertEq(sumInitial, 150, "Initial sum should be 150");

        // Simulate an external actor adding records concurrently (in subsequent transactions but same testing block context)
        // by switching context with vm.startPrank
        address attacker = address(0xABCD);
        vm.startPrank(attacker);
        fixedPhantom.addRecord(60);
        fixedPhantom.addRecord(70);
        vm.stopPrank();

        uint256 sumAfter = fixedPhantom.processRecords();
        assertEq(sumAfter, 280, "Sum after attacker adds records should be 280");
    }
}
