pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The FixedContract and SafeLibrary from 1.7.2-Unsafe-External-Library-Call-fixed.sol
library SafeLibrary {
    function doSomething(uint256 _val) internal pure returns (uint256) {
        return _val * 2;
    }
}

contract FixedContract {
    address public owner;
    uint256 public someValue;
    
    constructor() {
        owner = msg.sender;
    }
    
    function execute(uint256 _val) public {
        someValue = SafeLibrary.doSomething(_val);
    }
    
    // Accept Ether with empty calldata
    receive() external payable {}
}

// A dummy malicious library contract to simulate an external malicious library.
contract MaliciousLibrary {
    // This function pretends to be a malicious version by multiplying by 10
    function doSomething(uint256 _val) public pure returns (uint256) {
        return _val * 10;
    }
}

contract FixedContractTest is Test {
    FixedContract fixedContract;

    function setUp() public {
        fixedContract = new FixedContract();
    }

    // Test that execute correctly doubles the input value using the internal SafeLibrary
    function testExecuteDoublesValue() public {
        fixedContract.execute(7);
        uint256 result = fixedContract.someValue();
        assertEq(result, 14, "Expected value to be doubled by SafeLibrary.");
    }

    // Test that even if a malicious library is deployed, FixedContract still uses its internal SafeLibrary.
    function testMaliciousLibraryCannotExploit() public {
        // Deploy malicious library contract and use its address in a dummy way to avoid unused variable warning
        MaliciousLibrary malicious = new MaliciousLibrary();
        // Ensure the malicious library is deployed
        assertTrue(address(malicious) != address(0), "MaliciousLibrary should have a non-zero address");

        // Now call FixedContract.execute which should use SafeLibrary.doSomething, not the malicious one
        fixedContract.execute(3);
        uint256 result = fixedContract.someValue();
        // Instead of multiplying by 10, SafeLibrary multiplies by 2 so expect 6
        assertEq(result, 6, "FixedContract should use the internal SafeLibrary, not the malicious one.");
    }

    // Test that owner remains unchanged after calling execute
    function testOwnerRemainsUnchanged() public {
        address expectedOwner = fixedContract.owner();
        fixedContract.execute(5);
        address ownerAfter = fixedContract.owner();
        assertEq(ownerAfter, expectedOwner, "Owner should remain the deployer.");
    }

    // Test receiving Ether via the receive() function by sending Ether with empty calldata
    function testReceiveEther() public {
        uint256 sendAmount = 1 ether;

        // Make sure the test contract has enough Ether
        vm.deal(address(this), 10 ether);

        // Send Ether using an empty calldata call to trigger the receive() function
        (bool success, ) = address(fixedContract).call{value: sendAmount}("");
        assertTrue(success, "Ether transfer should succeed using the receive() function.");
        
        // Verify the balance of FixedContract increased by sendAmount
        uint256 balance = address(fixedContract).balance;
        assertEq(balance, sendAmount, "FixedContract should have received the Ether.");
    }
}
