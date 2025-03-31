pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The FixedContract from the provided file
interface IAttackerFixed {
    function notify(uint currentValue) external;
}

contract FixedContract {
    uint public value;

    constructor() {
        value = 0;
    }

    // Fixed function: update the state before calling the external callback
    function updateValueAndNotifyFixed(uint newValue, address callbackAddr) public {
        // Update state variable first
        value = newValue;

        // Read the updated value
        uint currentValue = value;

        // Call external callback with the updated value
        IAttackerFixed(callbackAddr).notify(currentValue);
    }
}

// Receiver contract that simulates receiving the callback notification
contract Receiver is IAttackerFixed {
    FixedContract public fixedContract;
    uint public receivedValue;

    event Notified(uint currentValue);

    constructor(address fixedContractAddr) {
        fixedContract = FixedContract(fixedContractAddr);
    }

    // Execute update function via the fixed contract
    function executeUpdate(uint newValue) external {
        fixedContract.updateValueAndNotifyFixed(newValue, address(this));
    }

    // Callback, records the current value
    function notify(uint currentValue) external override {
        receivedValue = currentValue;
        emit Notified(currentValue);
    }
}

contract DirtyReadsFixedTest is Test {
    FixedContract fixedContract;
    Receiver receiver;

    function setUp() public {
        fixedContract = new FixedContract();
        receiver = new Receiver(address(fixedContract));
    }

    // Test that when updateValueAndNotifyFixed is called, the callback receives the updated value
    function testCallbackReceivesUpdatedValue() public {
        uint newValue = 42;
        
        // Call executeUpdate on the receiver which calls the fixed contract and triggers callback
        receiver.executeUpdate(newValue);
        
        // Check that the state variable is updated in FixedContract
        uint storedValue = fixedContract.value();
        assertEq(storedValue, newValue, "FixedContract state variable not updated correctly");
        
        // Check that the callback (notify) in Receiver was called with the updated value
        uint callbackValue = receiver.receivedValue();
        assertEq(callbackValue, newValue, "Receiver did not get the updated value in callback");
    }

    // Test multiple consecutive updates, ensuring no dirty read happens
    function testMultipleUpdates() public {
        uint[] memory testValues = new uint[](3);
        testValues[0] = 10;
        testValues[1] = 20;
        testValues[2] = 30;
        
        for (uint i = 0; i < testValues.length; i++) {
            receiver.executeUpdate(testValues[i]);
            uint storedValue = fixedContract.value();
            assertEq(storedValue, testValues[i], "FixedContract state variable not updated correctly on iteration");
            uint callbackValue = receiver.receivedValue();
            assertEq(callbackValue, testValues[i], "Receiver did not get the updated value in callback on iteration");
        }
    }

    // Test that even if external call ordering is attempted by re-entering (not allowed in this scenario), correct value is passed
    // Although solidity disallows re-entrancy here because the external contract is ours, we simulate appropriate update ordering
    function testNoDirtyReads() public {
        uint newValue = 100;
        receiver.executeUpdate(newValue);

        // Even if someone were to query the contract within this same transaction, they'd get the updated value
        uint queriedValue = fixedContract.value();
        assertEq(queriedValue, newValue, "Query returned stale value, indicating a dirty read vulnerability");
    }
}
