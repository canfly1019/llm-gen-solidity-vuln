pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.4.1-Wrong-Function-Call-fixed.sol";

contract FixedReservationTest is Test {
    // The hardcoded restaurant address used in FoodBudgetWallet_Fixed
    address constant RESTAURANT_ADDR = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    // Deploy a dummy RealRestaurant and then force its code to the constant address
    function _setUpRestaurantCode() internal returns (RealRestaurant) {
        // Deploy a RealRestaurant instance
        RealRestaurant realRestaurant = new RealRestaurant();
        
        // Overwrite the code at the hardcoded restaurant address so that it behaves as a RealRestaurant
        // This uses Foundry's cheatcode vm.etch
        vm.etch(RESTAURANT_ADDR, address(realRestaurant).code);

        return realRestaurant;
    }

    // Test that a direct reservation through FoodBudgetWallet_Fixed succeeds
    function testDirectReservation() public {
        // Set up the restaurant at the expected address
        RealRestaurant realRestaurant = _setUpRestaurantCode();

        // Deploy FoodBudgetWallet_Fixed with an initial balance so that it can forward 1 ether
        FoodBudgetWallet_Fixed foodWallet = new FoodBudgetWallet_Fixed{value: 1 ether}();

        // Record the balance of the restaurant before making reservation
        uint beforeBal = RESTAURANT_ADDR.balance;

        // Make a reservation for, say, 3 seats
        foodWallet.makeReservation(3);

        // The RealRestaurant requires exactly 1 ether to be sent so the balance difference should be 1 ether
        uint afterBal = RESTAURANT_ADDR.balance;
        assertEq(afterBal - beforeBal, 1 ether, "Restaurant should receive 1 ether");
    }

    // Test that an attack attempt via AttackAttempt_Fixed ends up calling the correct function
    function testAttackAttemptSucceeds() public {
        // Set up the restaurant at the expected address
        RealRestaurant realRestaurant = _setUpRestaurantCode();

        // Deploy the AttackAttempt_Fixed contract. Its constructor deploys a FoodBudgetWallet_Fixed internally.
        AttackAttempt_Fixed attackAttempt = new AttackAttempt_Fixed();

        // Fund the victim FoodBudgetWallet_Fixed so that it has at least 1 ether to forward
        // Using Foundry cheatcode vm.deal to set the balance directly
        vm.deal(address(attackAttempt.victim()), 1 ether);

        // Record the balance of the restaurant before attack
        uint beforeBal = RESTAURANT_ADDR.balance;

        // Execute the attack attempt by sending exactly 1 ether (meeting the minimum requirement)
        attackAttempt.executeAttack{value: 1 ether}(2);

        // Check that the restaurant received 1 ether
        uint afterBal = RESTAURANT_ADDR.balance;
        assertEq(afterBal - beforeBal, 1 ether, "Restaurant should receive 1 ether despite attack attempt");
    }

    // Test that the attack attempt reverts when less than 1 ether is provided
    function testAttackAttemptInsufficientEther() public {
        // Set up the restaurant at the expected address
        RealRestaurant realRestaurant = _setUpRestaurantCode();

        // Deploy the AttackAttempt_Fixed contract
        AttackAttempt_Fixed attackAttempt = new AttackAttempt_Fixed();

        // We don't need to fund the victim here because the execution should revert before attempting the reservation
        vm.expectRevert("min 1 ether required");
        attackAttempt.executeAttack{value: 0.5 ether}(2);
    }
}
