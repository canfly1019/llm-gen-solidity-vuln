pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/7.1.1-Integer-Underflow-fixed.sol";

contract TestIntegerUnderflowFixed is Test {
    FixedMappingSym1 fixedContract;
    AttackFixed attackContract;

    function setUp() public {
        fixedContract = new FixedMappingSym1();
        attackContract = new AttackFixed(address(fixedContract));
    }

    // Test that underflow is prevented when subtracting more than the current value (which is 0 by default)
    function testUnderflowPreventsDirectCall() public {
        // Expect revert due to subtraction underflow
        vm.expectRevert(bytes("Subtraction underflow"));
        fixedContract.init(1, 1);
    }

    // Test that the attack contract fails to perform underflow attack
    function testAttackFixedContract() public {
        bool result = attackContract.tryAttack(2);
        assertEq(result, false, "Attack should not succeed, underflow prevented");
    }

    // Test a scenario where subtraction is valid by pre-setting the mapping value in storage
    function testValidSubtraction() public {
        uint256 key = 100;
        uint256 initialValue = 5;
        uint256 subtractValue = 3;

        // We use Foundry's cheat code vm.store to set the storage directly.
        // The mapping 'map' is at storage slot 0, and its value for a key is stored at:
        // keccak256(abi.encode(key, uint256(0)))
        bytes32 storageSlot = keccak256(abi.encode(key, uint256(0)));
        vm.store(address(fixedContract), storageSlot, bytes32(uint256(initialValue)));

        // Call init with subtractValue. This should succeed, resulting in value = initialValue - subtractValue
        fixedContract.init(key, subtractValue);

        // Validate the new value in the mapping
        uint256 expected = initialValue - subtractValue;
        uint256 actual = fixedContract.map(key);
        assertEq(actual, expected, "Subtraction did not perform as expected");
    }
}
