pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the target contract. Adjust the import path as needed to locate the file.
import "../src/5.15-Typographical-Error-fixed.sol";


contract TypoOneCommandFixedTest is Test {
    TypoOneCommandFixed target;

    // Setup function to deploy the target contract before each test
    function setUp() public {
        target = new TypoOneCommandFixed();
    }

    // This test confirms that repeated calls to alwaysOne() correctly increment numberOne.
    function testIncrement() public {
        // initial value is 1
        uint initial = target.numberOne();
        assertEq(initial, 1, "Initial value should be 1");
        
        // Call alwaysOne() 5 times
        for (uint i = 0; i < 5; i++) {
            target.alwaysOne();
        }
        
        // After 5 calls, expect the value to be 1 + 5 = 6
        uint expected = 6;
        uint result = target.numberOne();
        assertEq(result, expected, "numberOne should be 6 after five increments");
    }

    // Additional test: calling alwaysOne ten times should give 11.
    function testIncrementTenTimes() public {
        for (uint i = 0; i < 10; i++) {
            target.alwaysOne();
        }
        uint expected = 11; // initial 1 + 10
        uint result = target.numberOne();
        assertEq(result, expected, "numberOne should be 11 after ten increments");
    }

    // This test ensures that no unintended behavior (like value resetting or incorrect arithmetic) occurs
    function testConsistencyAfterMultipleCalls() public {
        // Call alwaysOne() 3 times
        for (uint i = 0; i < 3; i++) {
            target.alwaysOne();
        }
        uint interim = target.numberOne();
        assertEq(interim, 4, "After 3 increments, numberOne should be 4");

        // Call alwaysOne() 2 more times
        for (uint i = 0; i < 2; i++) {
            target.alwaysOne();
        }
        uint finalVal = target.numberOne();
        assertEq(finalVal, 6, "After a total of 5 increments, numberOne should be 6");
    }
}
