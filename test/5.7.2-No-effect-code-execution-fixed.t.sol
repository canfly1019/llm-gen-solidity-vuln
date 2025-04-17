pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.7.2-No-effect-code-execution-fixed.sol";

contract NoEffectCodeExecutionTest is Test {

    // Test that contract B deploys correctly
    function testBDeploys() public {
        B b = new B();
        assert(address(b) != address(0));
    }

    // Test that AttackFixed contract deploys properly and its B instance is valid
    function testAttackFixedDeploys() public {
        AttackFixed attackFixed = new AttackFixed();
        B b = attackFixed.fixedB();
        assert(address(b) != address(0));
    }

    // Test to ensure that the deployed contract B has a small bytecode size, indicating that no extra redundant code is present.
    // Note: The threshold value is chosen based on expected minimal code size in an optimized compilation.
    function testBCodeSize() public {
        B b = new B();
        uint256 codeSize = address(b).code.length;
        // The threshold value may need tuning if compiler settings or optimizations differ.
        // However, for a minimal contract with no extra redundancies, we expect a very small bytecode size.
        uint256 threshold = 500;
        assertLt(codeSize, threshold);
    }
}
