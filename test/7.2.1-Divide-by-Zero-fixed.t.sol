pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/7.2.1-Divide-by-Zero-fixed.sol";

contract DivideByZeroTest is Test {
    FixedDemo demo;

    function setUp() public {
        demo = new FixedDemo();
    }

    // Test normal division with non-zero denominator
    function testDivideNormal() public {
        uint256 a = 10;
        uint256 b = 2;
        uint256 result = demo.tryDiv(a, b);
        assertEq(result, 5, "10 / 2 should equal 5");
    }

    // Test division by zero; expected behavior: return zero, not revert
    function testDivideByZero() public {
        uint256 a = 10;
        uint256 b = 0;
        uint256 result = demo.tryDiv(a, b);
        assertEq(result, 0, "Division by zero should return 0");
    }

    // Additional test: when numerator is zero
    function testZeroNumerator() public {
        uint256 a = 0;
        uint256 b = 10;
        uint256 result = demo.tryDiv(a, b);
        assertEq(result, 0, "0 / 10 should equal 0");
    }

    // Additional test: large numerator division
    function testLargeNumbers() public {
        uint256 a = 2**128;
        uint256 b = 2;
        uint256 result = demo.tryDiv(a, b);
        assertEq(result, a / b, "Large number division should work correctly");
    }
}
