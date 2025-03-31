pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The fixed contract
// SPDX-License-Identifier: MIT
contract CallInLoopFixed {
    address[] public destinations;
    mapping(address => uint) public credits;

    constructor(address[] memory newDestinations) {
        destinations = newDestinations;
    }

    function allowForPull(address receiver, uint amount) private {
        credits[receiver] += amount;
    }

    function distribute() external payable {
        // msg.value must be at least equal to the number of destinations
        require(msg.value >= destinations.length, "Insufficient Ether provided");
        for (uint i = 0; i < destinations.length; i++) {
            // Instead of directly transferring, we record the credit
            allowForPull(destinations[i], 1 wei);
        }
        // Any extra funds remain in the contract and can be withdrawn later
    }

    function withdrawCredits() public {
        uint amount = credits[msg.sender];
        require(amount != 0, "No credits available");
        require(address(this).balance >= amount, "Insufficient contract balance");
        credits[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // Allow contract to receive Ether
    receive() external payable {}
}

// A malicious receiver contract that reverts when receiving Ether
contract MaliciousReceiver {
    // This function will attempt to call withdrawCredits on the fixed contract
    // and its fallback will force the transfer to revert

    // callWithdraw will be called by the test to trigger a withdrawal
    function callWithdraw(address target) external returns (bool) {
        // calling withdrawCredits from this contract will result in triggering fallback
        (bool success, ) = target.call(abi.encodeWithSignature("withdrawCredits()"));
        return success;
    }

    // Fallback function that reverts any attempt to receive Ether
    receive() external payable {
        revert("I do not accept Ether");
    }
}

contract CallInLoopFixedTest is Test {
    CallInLoopFixed public fixedContract;
    MaliciousReceiver public malicious;
    address public honest;

    function setUp() public {
        // Use the test contract's address as the honest address
        honest = address(this);

        // Deploy the malicious contract
        malicious = new MaliciousReceiver();

        // Create an array of destination addresses including an honest and a malicious receiver
        address[] memory dests = new address[](2);
        dests[0] = honest;
        dests[1] = address(malicious);

        // Deploy the fixed contract with the provided destinations
        fixedContract = new CallInLoopFixed(dests);
    }

    // Test that distribute() properly assigns credits to all destinations
    function testDistributeCredits() public {
        // Provide exactly 2 wei (because we have 2 destinations)
        fixedContract.distribute{value: 2 wei}();
        
        // Check that both honest and malicious addresses got credited with 1 wei
        uint honestCredit = fixedContract.credits(honest);
        uint maliciousCredit = fixedContract.credits(address(malicious));
        assertEq(honestCredit, 1 wei, "Honest address should have 1 wei credit");
        assertEq(maliciousCredit, 1 wei, "Malicious address should have 1 wei credit");
    }

    // Test that honest address can withdraw its credits successfully
    function testHonestWithdrawal() public {
        // Fund the contract by distributing 2 wei
        fixedContract.distribute{value: 2 wei}();

        // Check starting balance for honest address
        uint startBalance = address(this).balance;
        
        // Withdraw credits as the honest user
        fixedContract.withdrawCredits();
        
        // The contract should have transferred 1 wei to the honest address
        uint endBalance = address(this).balance;
        assertEq(endBalance - startBalance, 1 wei, "Honest user should receive 1 wei");

        // Confirm that credits is now zero
        uint remainingCredit = fixedContract.credits(honest);
        assertEq(remainingCredit, 0, "Credits for honest address should be zero after withdrawal");
    }

    // Test that a withdrawal by a malicious receiver fails without affecting others
    function testMaliciousWithdrawalFails() public {
        // Fund the contract by distributing 2 wei
        fixedContract.distribute{value: 2 wei}();

        // Attempt withdrawal from the malicious contract using a helper function
        // Since MaliciousReceiver reverts on receiving Ether, the transfer will fail.
        bool success = malicious.callWithdraw(address(fixedContract));
        
        // The call should return false
        assertTrue(!success, "Withdrawal from malicious contract should fail");

        // Ensure that the malicious credit remains unchanged (since the withdrawal failed)
        uint maliciousCredit = fixedContract.credits(address(malicious));
        assertEq(maliciousCredit, 1 wei, "Malicious credit should remain since withdrawal failed");

        // Now, validate that the honest address can still withdraw successfully
        uint startBalance = address(this).balance;
        fixedContract.withdrawCredits();
        uint endBalance = address(this).balance;
        assertEq(endBalance - startBalance, 1 wei, "Honest user should still withdraw 1 wei successfully");
    }

    // Test that distribute() reverts when not enough Ether is sent
    function testDistributeInsufficientEther() public {
        // Expect revert due to insufficient Ether (we need at least 2 wei for 2 addresses)
        vm.expectRevert("Insufficient Ether provided");
        fixedContract.distribute{value: 1 wei}();
    }

    // Provide the contract with some Ether so that withdrawCredits can succeed
    function fundContract() internal {
        // Fund the test contract with some Ether and then send it to the fixedContract
        vm.deal(address(this), 10 ether);
        payable(address(fixedContract)).transfer(10 ether);
    }

    // Override receive to allow the test contract to accept Ether from the fixed contract (if needed)
    receive() external payable {}
}
