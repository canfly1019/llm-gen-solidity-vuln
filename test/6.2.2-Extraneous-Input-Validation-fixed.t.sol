pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/6.2.2-Extraneous-Input-Validation-fixed.sol";

contract FixedTest is Test {
    // Declare events for expectation matching
    event Result(int256 result);
    event Error(string message);

    // Test that Foo.baz works correctly with positive input
    function testFooBazPositive() public {
        Foo foo = new Foo();
        // When input is positive, function should return 42.
        uint256 result = uint256(foo.baz(1));
        assertEq(result, 42);

        result = uint256(foo.baz(100));
        assertEq(result, 42);
    }

    // Test that Foo.baz reverts when given non-positive input
    function testFooBazRevertsOnNonPositive() public {
        Foo foo = new Foo();

        // x = 0 should revert
        vm.expectRevert("x must be positive");
        foo.baz(0);

        // x negative should also revert
        vm.expectRevert("x must be positive");
        foo.baz(-5);
    }

    // Test that Bar.doubleBaz returns the expected value
    function testBarDoubleBaz() public {
        Bar bar = new Bar();
        // doubleBaz() calls Foo.baz(1) which returns 42, and then multiplies by 2 to return 84.
        assertEq(bar.doubleBaz(), 84);
    }

    // Test the AttackFixed contract functionality
    function testAttackFixed() public {
        AttackFixed attack = new AttackFixed();

        // Expect the event Result to be emitted with value 84
        vm.expectEmit(true, false, false, true);
        emit Result(84);

        // The attack function calls bar.doubleBaz() and should succeed, thus emitting a Result event with 84
        attack.attack();
    }
}
