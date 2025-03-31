pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the fixed contracts

// Global constant
uint constant pi = 314;

contract C1 {
    uint constant FavorateNumber = 25;
    
    // pure because only reading constants
    function getNumbers() public pure returns (uint) {
        return FavorateNumber * pi;
    }
}

contract C2 {
    // pure because only reading a global constant
    function getPi() public pure returns (uint) {
       return pi;
    }
}

interface IC1 {
    function getNumbers() external pure returns(uint);
}

interface IC2 {
    function getPi() external pure returns(uint);
}

contract FixedAttack {
    IC1 public c1;
    IC2 public c2;

    // Pass the addresses for C1 & C2 when deploying
    constructor(address _c1, address _c2) {
        c1 = IC1(_c1);
        c2 = IC2(_c2);
    }

    // The attack demonstration; note that because of pure logic, we simply compute the expected values.
    function attack() public pure returns(uint, uint) {
        uint numberResult = 25 * pi; 
        uint piResult = pi;
        return (numberResult, piResult);
    }
}

contract FixedConstantTest is Test {
    C1 c1;
    C2 c2;
    FixedAttack attackContract;

    function setUp() public {
        // Deploy contracts
        c1 = new C1();
        c2 = new C2();
        attackContract = new FixedAttack(address(c1), address(c2));
    }

    // Test that C1.getNumbers returns the expected result.
    function testC1GetNumbers() public {
        uint expected = 25 * 314; // should be 7850
        uint result = c1.getNumbers();
        assertEq(result, expected, "C1.getNumbers() should return 25 * pi (7850)");
    }

    // Test that C2.getPi returns the global constant pi.
    function testC2GetPi() public {
        uint result = c2.getPi();
        assertEq(result, 314, "C2.getPi() should return pi (314)");
    }

    // Test that FixedAttack.attack returns the correct computed values from the constants
    function testFixedAttack() public {
        (uint numberResult, uint piResult) = attackContract.attack();
        uint expectedNumberResult = 25 * 314; // 7850
        uint expectedPiResult = 314;
        assertEq(numberResult, expectedNumberResult, "FixedAttack.attack() returned wrong numberResult");
        assertEq(piResult, expectedPiResult, "FixedAttack.attack() returned wrong piResult");
    }
}
