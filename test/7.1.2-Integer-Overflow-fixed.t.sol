pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/7.1.2-Integer-Overflow-fixed.sol";

contract IntegerOverflowMappingSym1FixedTest is Test {
    IntegerOverflowMappingSym1Fixed public target;

    function setUp() public {
        target = new IntegerOverflowMappingSym1Fixed();
    }

    function testNormalAddition() public {
        // Check that mapping value is zero initially for key 1
        uint256 initial = target.map(1);
        assertEq(initial, 0, "Mapping should be zero initially");

        // Perform safe additions
        target.init(1, 100);
        uint256 firstAddition = target.map(1);
        assertEq(firstAddition, 100, "Mapping after first init should be 100");

        target.init(1, 50);
        uint256 secondAddition = target.map(1);
        assertEq(secondAddition, 150, "Mapping after second init should be 150");
    }

    function testOverflowReverts() public {
        // First, set the mapping for key 1 to the max value safely
        target.init(1, type(uint256).max);
        
        // Expect a revert when we perform an addition that would overflow.
        // Due to Solidity 0.8.0's built-in overflow checks, a panic error (0x11) is raised.
        vm.expectRevert(stdError.arithmeticError);
        target.init(1, 1);
    }
}
