pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/7.2.2-Integer-Division-fixed.sol";

contract DivideTest is Test {

    // Test that the calcul function returns the expected result for fixed precision division
    function testCalculWithPrecision() public {
        Divide d = new Divide();
        uint result = d.calcul(4, 5, 2);
        // With precision 2, 4/5 should be 0.80, thus returning 80
        assertEq(result, 80, "calcul(4,5,2) should return 80");

        // Additional test: 3/2 with precision 3 should yield 1500, representing 1.500
        result = d.calcul(3, 2, 3);
        assertEq(result, 1500, "calcul(3,2,3) should return 1500");
    }

    // Test that attempting division by zero reverts with the appropriate error message
    function testDivisionByZero() public {
        Divide d = new Divide();
        vm.expectRevert(bytes("Division by zero"));
        d.calcul(4, 0, 2);
    }

    // Test that the FixedAttacker contract's testCalculation function correctly verifies the division result
    function testFixedAttacker() public {
        FixedAttacker attacker = new FixedAttacker();
        uint result = attacker.testCalculation();
        assertEq(result, 80, "FixedAttacker testCalculation should return 80");
    }
}
