pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Assuming the fixed contract is in the same directory and named accordingly
import "../src/5.5-Wrong-class-inheritance-order-fixed.sol";

contract SalesInheritanceTest is Test {
    Sales public sales;
    Attack public attack;
    address public deployer;
    address public attacker = address(0xBEEF);

    // Set up initial conditions
    function setUp() public {
        // Use the test contract as deployer
        deployer = address(this);
        // Fund deployer and attacker
        vm.deal(deployer, 200 ether);
        vm.deal(attacker, 200 ether);

        // Deploy the Sales contract. The deployer (this contract) becomes whitelisted
        sales = new Sales();

        // Deploy the Attack contract from the attacker to simulate an attack
        vm.startPrank(attacker);
        attack = new Attack(address(sales));
        vm.stopPrank();
    }

    // Test that a purchase exceeding the cap will revert even for a whitelisted buyer
    function testBuyExceedsCap() public {
        // First, make a valid purchase of 90 ether
        sales.buy{value: 90 ether}();
        // Check that weiRaised was updated
        assertEq(sales.weiRaised(), 90 ether);

        // Now, try purchasing an amount that would exceed the cap (cap is 100 ether)
        // Even though the deployer is whitelisted, the cap-check in Utils should prevent overshooting the cap
        vm.expectRevert("Purchase not valid");
        sales.buy{value: 15 ether}();

        // weiRaised remains the same
        assertEq(sales.weiRaised(), 90 ether);
    }

    // Test that an attack using the Attack contract fails when attempting to bypass the cap
    function testAttackFails() public {
        // First, make a valid purchase of 90 ether from the whitelisted deployer
        sales.buy{value: 90 ether}();
        assertEq(sales.weiRaised(), 90 ether);

        // Now, have the attacker (via the Attack contract) attempt a purchase that would exceed the cap
        // Even if the attacker could try to use whitelist bypassing, the modified inheritance order ensures the cap-check is enforced
        vm.startPrank(attacker);
        vm.expectRevert("Purchase not valid");
        attack.attack{value: 15 ether}();
        vm.stopPrank();

        // Confirm that weiRaised has not increased beyond the previous valid amount
        assertEq(sales.weiRaised(), 90 ether);
    }

    // Helper function to test valid purchase conditions within sale period and under cap
    function testValidPurchaseUnderCap() public {
        // A purchase that is valid should succeed when within sale period and under the cap
        sales.buy{value: 10 ether}();
        assertEq(sales.weiRaised(), 10 ether);
    }
}
