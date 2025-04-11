pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.7.4-Inefficient-Operation-Sequence-fixed.sol";

contract FixedContractTest is Test {
    FixedContract fixedContract;

    function setUp() public {
        fixedContract = new FixedContract();
    }

    // Test that adding data and computing sum works correctly
    function testAddDataAndSumData() public {
        uint numEntries = 50;
        uint expectedSum = 0;
        
        // Add numbers 1 through numEntries
        for (uint i = 1; i <= numEntries; i++) {
            fixedContract.addData(i);
            expectedSum += i;
        }

        uint sum = fixedContract.sumData();
        assertEq(sum, expectedSum, "Sum computed by sumData does not match expected result");
    }

    // Test that the efficiency improvement holds by running sumData on a large dataset
    // We don't have a direct gas comparator, but we can ensure that the call succeeds under high load
    function testLargeDatasetSum() public {
        uint numEntries = 1000;
        uint expectedSum = 0;

        for (uint i = 1; i <= numEntries; i++) {
            fixedContract.addData(i);
            expectedSum += i;
        }

        // Record gas before and after, mainly to observe that the function doesn't run out of gas
        uint gasStart = gasleft();
        uint sum = fixedContract.sumData();
        uint gasUsed = gasStart - gasleft();
        
        // Log gas usage for manual inspection
        emit log_named_uint("Gas used in sumData for 1000 entries", gasUsed);

        assertEq(sum, expectedSum, "Sum computed for large dataset does not match expected");
    }

    // Additional test to ensure that multiple calls to addData work as intended
    function testMultipleAddDataCalls() public {
        // First add a set of values
        fixedContract.addData(10);
        fixedContract.addData(20);
        fixedContract.addData(30);

        uint sum1 = fixedContract.sumData();
        assertEq(sum1, 60, "Initial sum should be 60");
        
        // Add additional values
        fixedContract.addData(40);
        fixedContract.addData(50);

        // Expect sum to update accordingly
        uint sum2 = fixedContract.sumData();
        assertEq(sum2, 150, "Updated sum should be 150");
    }
}
