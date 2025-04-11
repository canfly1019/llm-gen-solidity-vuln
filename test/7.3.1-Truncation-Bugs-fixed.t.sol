pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/7.3.1-Truncation-Bugs-fixed.sol";

contract TruncationBugsFixedTest is Test {
    FixedContract fixedContract;
    AttackContractFixed attackContract;

    // This value is the maximum uint32 value
    uint256 constant UINT32_MAX = type(uint32).max;

    function setUp() public {
        fixedContract = new FixedContract();
        attackContract = new AttackContractFixed(payable(address(fixedContract)));
    }

    // Test that calling attack() with msg.value <= uint32 max reverts
    function testAttackRevertsWithInsufficientEther() public {
        // Try using exactly uint32 max value, which should fail because the require expects > uint32 max
        vm.expectRevert();
        attackContract.attack{value: UINT32_MAX}();
    }

    // Test that a proper attack with msg.value > uint32 max records balance correctly
    function testAttackSucceedsAndRecordsCorrectBalance() public {
        // Use a value slightly larger than uint32 max
        uint256 attackValue = UINT32_MAX + 1;

        // Execute attack from the attackContract
        attackContract.attack{value: attackValue}();

        // Verify that the FixedContract correctly records the entire msg.value sent
        uint256 recordedBalance = fixedContract.getBalance(address(attackContract));
        assertEq(recordedBalance, attackValue, "Balance should match the Ether sent in the attack");

        // Also test the checkBalance function of the AttackContractFixed
        uint256 checkedBalance = attackContract.checkBalance();
        assertEq(checkedBalance, attackValue, "checkBalance should return the correct Ether amount");
    }
}
