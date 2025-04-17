pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.6.7-Non-Identifiable-Order-in-Map-Structure-Iteration-fixed.sol";

contract FixedOrderProcessorTest is Test {
    FixedOrderProcessor processor;

    // Setup the contract before each test
    function setUp() public {
        processor = new FixedOrderProcessor();
    }

    // Test that adding the same order id twice reverts
    function testAddDuplicateOrderReverts() public {
        // First addition should succeed
        processor.addOrder{value: 1 ether}(1, 100);

        // Second addition with same id should revert with "Order already exists"
        vm.expectRevert("Order already exists");
        processor.addOrder{value: 1 ether}(1, 200);
    }

    // Test that processOrders only processes each order once
    function testProcessOrdersProcessesOnce() public {
        // Add two distinct orders
        processor.addOrder{value: 1 ether}(1, 100);
        processor.addOrder{value: 1 ether}(2, 200);

        // Expect events in the order of processing
        // OrderProcessed(uint id, uint amount, address buyer)
        vm.expectEmit(true, true, true, true);
        emit OrderProcessed(1, 100, address(this));
        vm.expectEmit(true, true, true, true);
        emit OrderProcessed(2, 200, address(this));

        // Process orders
        processor.processOrders();

        // After processing, orderIds should be cleared
        uint orderIdsLength = getOrderIdsLength();
        assertEq(orderIdsLength, 0, "orderIds array should be empty after processing");
    }

    // Utility function to get the length of the orderIds array using a static call
    function getOrderIdsLength() internal returns (uint) {
        // Because orderIds is public, Solidity generates a getter that returns the element at index.
        // However, there's no auto-generated getter for the length of the dynamic array.
        // We simulate this by iterating until we get an error. 
        // Alternatively, we can add an external method in the contract to return the length if necessary.
        // For our purposes, we can simulate the length by calling processOrders and comparing state before and after.
        // Since processOrders deletes the orderIds array, we can infer that orderIds is empty.
        
        // Another option is to use low-level staticcall with the keccak layout, but for simplicity we trust the event.
        // Instead we check that adding a new order with an already used id (if not cleared) would revert.
        // Here, however, note that the orderExists mapping is never cleared, so we cannot rely on addOrder behavior.
        
        // Therefore, we will deploy a new contract to simulate length state. 
        // Actually, we can mirror the behavior by reading storage slot manually using vm.load.
        
        // orderIds is the second state variable (after orders mapping), but because mapping's slots are computed differently,
        // we can assume orderIds occupies slot 1 (if no other state variable is interfering). 
        // The layout for dynamic arrays: slot contains length in first 32 bytes.
        
        // Assumption: orderIds is declared after orders, so it likely occupies slot 1.
        
        bytes32 slot = vm.load(address(processor), bytes32(uint256(1)));
        return uint256(slot);
    }

    // Event to match the one from the contract
    event OrderProcessed(uint id, uint amount, address buyer);
}
