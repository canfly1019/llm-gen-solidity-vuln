pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/6.1.4-Transfer-Pre-Condition-Dependent-on-Transaction-Order-fixed.sol";

contract SolutionTransactionOrderingTest is Test {
    SolutionTransactionOrdering public solution;
    AttackFixed public attacker;

    address owner = address(0xABCD);
    address attackerAddress = address(0xBEEF);

    function setUp() public {
        // deploy the solution contract with owner as address(0xABCD)
        vm.prank(owner);
        solution = new SolutionTransactionOrdering();

        // deploy the attack contract from attackerAddress, it just calls the solution
        vm.prank(attackerAddress);
        attacker = new AttackFixed(address(solution));
    }

    // Test that buying with correct txCounter works (no reversion)
    function testBuyWithCorrectTxCounter() public {
        // Initially, txCounter is 0
        uint256 currentCounter = solution.getTxCounter();
        assertEq(currentCounter, 0, "Initial txCounter should be 0");
        
        // Buy with correct txCounter
        uint256 returnedPrice = solution.buy(currentCounter);
        assertEq(returnedPrice, solution.getPrice(), "Returned price should match contract price");
    }

    // Test that buying with an incorrect txCounter reverts
    function testBuyWithIncorrectTxCounter() public {
        uint256 wrongCounter = solution.getTxCounter() + 1;
        vm.expectRevert(bytes("Transaction ordering violation"));
        solution.buy(wrongCounter);
    }

    // Test that after price change, the txCounter is updated and any attempt to buy using old counter fails
    function testTxCounterUpdatedAfterPriceChange() public {
        // Save current state
        uint256 initialCounter = solution.getTxCounter();
        uint256 initialPrice = solution.getPrice();
        
        // owner calls setPrice, updating the price and txCounter
        uint256 newPrice = 200;
        vm.prank(owner);
        solution.setPrice(newPrice);
        
        // Check that txCounter has been incremented and price updated
        uint256 updatedCounter = solution.getTxCounter();
        uint256 updatedPrice = solution.getPrice();
        
        assertEq(updatedCounter, initialCounter + 1, "txCounter should be incremented by 1");
        assertEq(updatedPrice, newPrice, "Price should be updated to newPrice");
        
        // old txCounter value should fail
        vm.expectRevert(bytes("Transaction ordering violation"));
        solution.buy(initialCounter);
        
        // Buying with updated counter should succeed
        uint256 retPrice = solution.buy(updatedCounter);
        assertEq(retPrice, newPrice, "Returned price should match updated price");
    }

    // Test the AttackFixed contract: using incorrect txCounter should revert, demonstrating the fix.
    function testAttackFailsWithWrongTxCounter() public {
        // Owner updates the price to change txCounter
        uint256 newPrice = 300;
        vm.prank(owner);
        solution.setPrice(newPrice);

        // Attacker attempting to attack using a fake txCounter (e.g., 0) should revert
        vm.prank(attackerAddress);
        uint256 fakeTxCounter = 0; // this is outdated
        vm.expectRevert(bytes("Transaction ordering violation"));
        attacker.executeAttack(fakeTxCounter);
    }

    // Test that if the attacker tries to get the correct txCounter, the purchase goes through normally - demonstrating no backdoor
    function testAttackSucceedsWithCorrectTxCounter() public {
        // Owner updates price, incrementing txCounter
        uint256 newPrice = 400;
        vm.prank(owner);
        solution.setPrice(newPrice);

        // Attacker attempts to use the correct txCounter value
        uint256 correctTxCounter = solution.getTxCounter();
        // This should not revert because the attacker supplies the correct txCounter
        vm.prank(attackerAddress);
        uint256 priceFromBuy = solution.buy(correctTxCounter);
        assertEq(priceFromBuy, newPrice, "Price should match the updated newPrice");
    }
}
