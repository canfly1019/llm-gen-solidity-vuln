pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.6.4-Missing-type-in-variable-declaration-fixed.sol";

contract FixedContractTest is Test {
    FixedContract public fixedContract;

    function setUp() public {
        fixedContract = new FixedContract();
    }

    function testAttackReturnsCorrectSum() public {
        // Expected sum: 0 + 1 + 2 + ... + 256 = (256 * 257) / 2 = 32896
        uint256 expectedSum = 32896;
        uint256 result = fixedContract.attack();
        
        assertEq(result, expectedSum, "attack() did not return the correct sum");
    }

    function testCalculateSum() public {
        // Directly test the calculateSum() function
        uint256 expectedSum = 32896;
        uint256 result = fixedContract.calculateSum();
        
        assertEq(result, expectedSum, "calculateSum() did not return the correct sum");
    }
}
