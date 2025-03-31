pragma solidity ^0.8.0;

import "forge-std/Test.sol";
// Import the fixed contract
import "../src/2.1.3-Incorrect-Revert-Implementation-in-a-Loop-fixed.sol";


// A helper contract that accepts ether without reverting
contract GoodReceiver {
    receive() external payable {}
}


contract NaiveBankFixedTest is Test {
    NaiveBankFixed public bank;
    address public deployer;

    // setUp deploys the bank contract from a dedicated EOA so that the initial winner does not affect our tests
    function setUp() public {
        deployer = vm.addr(1);
        vm.prank(deployer);
        bank = new NaiveBankFixed();
        // Fund the bank contract with 10 ether for transfers
        vm.deal(address(bank), 10 ether);
    }

    // Test that a successful transfer works when all winners properly accept funds
    function testSuccessfulTransferNoAttack() public {
        // Deploy a GoodReceiver that will accept funds
        GoodReceiver goodReceiver = new GoodReceiver();
        
        // Add GoodReceiver as an extra winner. Note: winners array now contains deployer (an EOA) and goodReceiver
        vm.prank(deployer);
        bank.addWinner(payable(address(goodReceiver)));

        // Record initial balances
        uint initialGoodReceiverBalance = address(goodReceiver).balance;
        uint initialBankBalance = address(bank).balance;
        
        // Call setTransfer() from deployer; since both recipients accept ether, the transfer should succeed
        vm.prank(deployer);
        bank.setTransfer();
        
        // The reward is 1 ether per winner. Two winners should result in 2 ether being sent from the bank
        assertEq(address(bank).balance, initialBankBalance - 2 ether, "Bank balance should decrease by 2 ether after transfer");
        
        // Check that GoodReceiver received 1 ether
        assertEq(address(goodReceiver).balance, initialGoodReceiverBalance + 1 ether, "GoodReceiver should receive 1 ether reward");
        
        // Verify that both winners were marked as processed
        bool processedDeployer = bank.processed(payable(deployer));
        bool processedReceiver = bank.processed(payable(address(goodReceiver)));
        assertTrue(processedDeployer, "Deployer should be marked processed");
        assertTrue(processedReceiver, "GoodReceiver should be marked processed");
    }

    // Test that the transfer reverts entirely when one of the winners is an attacker forcing a revert
    function testTransferRevertsOnAttack() public {
        // Deploy the AttackFixed contract which will purposely revert on receiving funds
        vm.prank(deployer);
        AttackFixed attackContract = new AttackFixed(address(bank));
        
        // Add the attack contract as a winner
        vm.prank(deployer);
        bank.addWinner(payable(address(attackContract)));

        // Record the bank's initial balance
        uint initialBankBalance = address(bank).balance;
        
        // Expect the transaction to revert with the specified error message
        vm.prank(deployer);
        vm.expectRevert("Send failed, reverting transaction");
        bank.setTransfer();
        
        // After the revert, state changes must be rolled back. Neither the deployer nor the attack contract should be marked processed
        bool processedDeployer = bank.processed(payable(deployer));
        bool processedAttack = bank.processed(payable(address(attackContract)));
        assertTrue(!processedDeployer, "Deployer should not be marked processed after revert");
        assertTrue(!processedAttack, "Attack contract should not be marked processed after revert");
        
        // The bank's balance remains unchanged as the whole transaction reverted
        assertEq(address(bank).balance, initialBankBalance, "Bank balance should remain unchanged after revert");
    }
}
