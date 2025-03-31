pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Interface as provided
interface ICallable {
    function callMe() external;
}

// HardcodedGood contract with fixed gas forwarding in low-level calls
contract HardcodedGood {
    address payable public _callable;
    ICallable public callable;

    // Constructor receives target contract address
    constructor(address payable _target) payable {
        _callable = _target;
        callable = ICallable(_target);
    }
    
    // Uses transfer, which forwards a fixed 2300 gas
    function doTransfer(uint256 amount) public {
        _callable.transfer(amount);
    }
    
    // Uses send, which also forwards a fixed 2300 gas
    function doSend(uint256 amount) public returns (bool) {
        bool success = _callable.send(amount);
        return success;
    }
    
    // Fixed low-level call: forwards all remaining gas
    function callLowLevel() public {
        (bool success, ) = _callable.call{value: 0}("");
        require(success, "callLowLevel failed");
    }
    
    // Calls the target contract's callMe function with full gas
    function callWithArgs() public {
        callable.callMe();
    }
}

// A helper target contract that will simulate a potential gas issue when called with fixed gas amounts
// The fallback and receive functions require more than 3000 gas to succeed. Thus, using transfer or send
// (which supply only 2300 gas) will fail, while calls that forward all gas should work.
contract ExpensiveReceiver is ICallable {
    bool public called;

    // Fallback function used when no data is provided
    fallback() external payable {
        // Require that sufficient gas is forwarded
        require(gasleft() > 3000, "Not enough gas forwarded in fallback");
    }

    // Receive function for plain ETH transfers
    receive() external payable {
        require(gasleft() > 3000, "Not enough gas forwarded in receive");
    }

    // Implements the callMe function from ICallable. It simply sets a flag.
    function callMe() external override {
        called = true;
    }
}

// Forge Foundry tests for HardcodedGood focusing on the fixed gas forwarding vulnerability
contract TestHardcodedGood is Test {
    HardcodedGood public hardcodedGood;
    ExpensiveReceiver public expensiveReceiver;

    // Setup deploys both the ExpensiveReceiver and HardcodedGood contracts.
    // HardcodedGood is funded with some ETH to enable value transfers.
    function setUp() public {
         // Deploy the expensive receiver target contract
         expensiveReceiver = new ExpensiveReceiver();

         // Deploy HardcodedGood with the address of expensiveReceiver and send it 1 ether
         hardcodedGood = new HardcodedGood{value: 1 ether}(payable(address(expensiveReceiver)));
    }

    // Test that using transfer (doTransfer) fails when the target requires more gas than provided
    function testDoTransferFails() public {
         // Calling doTransfer uses transfer which forwards a fixed 2300 gas. 
         // Our ExpensiveReceiver's fallback/receive functions require >3000 gas, so it should revert.
         vm.expectRevert();
         hardcodedGood.doTransfer(0.1 ether);
    }

    // Test that using send (doSend) returns false when insufficient gas is forwarded
    function testDoSendFails() public {
         bool success = hardcodedGood.doSend(0.1 ether);
         assertFalse(success, "doSend should return false due to insufficient gas in fallback/receive");
    }

    // Test that the low-level call (callLowLevel) successfully forwards all gas, avoiding the fixed gas limitation
    function testCallLowLevelSucceeds() public {
         // Record the initial balance of ExpensiveReceiver (should be zero or unchanged)
         uint256 initialBalance = address(expensiveReceiver).balance;
         
         // callLowLevel forwards all gas, so its internal call should succeed without triggering the gas check
         hardcodedGood.callLowLevel();
         
         // Since callLowLevel sends 0 ETH, the balance should remain unchanged
         uint256 newBalance = address(expensiveReceiver).balance;
         assertEq(newBalance, initialBalance, "Balance should remain unchanged after callLowLevel");
    }

    // Test that callWithArgs successfully calls callMe on the target contract, setting its flag, using full gas forwarding
    function testCallWithArgsSucceeds() public {
         // Initially, the called flag should be false
         assertEq(expensiveReceiver.called(), false, "Initial called flag should be false");
         
         // callWithArgs should successfully invoke callMe, which sets the called flag to true
         hardcodedGood.callWithArgs();
         
         // Confirm that the flag is now set
         assertEq(expensiveReceiver.called(), true, "called flag should be true after callWithArgs");
    }
}
