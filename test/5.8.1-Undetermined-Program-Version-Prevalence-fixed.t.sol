pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.8.1-Undetermined-Program-Version-Prevalence-fixed.sol";

contract PragmaFixedTest is Test {
    PragmaFixed public target;
    AttackFixed public attacker;

    function setUp() public {
        // Deploy the fixed target contract using the locked compiler version 0.8.0
        target = new PragmaFixed();
        // Deploy the attacking contract with the target's address
        attacker = new AttackFixed(address(target));
    }

    // Test to ensure that the initial state variable 'x' in PragmaFixed is set to 1
    function testInitialValue() public {
        uint val = target.x();
        assertEq(val, 1, "Initial x value should be 1");
    }

    // Test to simulate an attack that calls callGetX() on AttackFixed
    // This ensures that even through the attack vector, the value remains 1, confirming the prevention of unexpected behavior due to compiler version differences
    function testAttackCallReturnsValue1() public {
        uint res = attacker.callGetX();
        assertEq(res, 1, "Attack call should return 1");
    }
}
