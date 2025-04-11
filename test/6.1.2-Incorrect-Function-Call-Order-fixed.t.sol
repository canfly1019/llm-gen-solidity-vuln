pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/6.1.2-Incorrect-Function-Call-Order-fixed.sol";

contract EthTxOrderDependenceMinimalTest is Test {
    EthTxOrderDependenceMinimal public ethTxContract;
    address public owner;
    address public nonOwner;
    
    // Set up our testing accounts and deploy the contract using the owner account
    function setUp() public {
        owner = vm.addr(1);
        nonOwner = vm.addr(2);
        // Fund the accounts
        vm.deal(owner, 10 ether);
        vm.deal(nonOwner, 10 ether);

        // Deploy the contract from the owner's address
        vm.startPrank(owner);
        ethTxContract = new EthTxOrderDependenceMinimal();
        vm.stopPrank();
    }
    
    // Test that the owner can successfully call claimReward
    function testOwnerCanClaimReward() public {
        uint256 rewardAmount = 2 ether;
        uint256 validSubmission = 15; // > 10

        // Check initial contract balance is zero
        assertEq(address(ethTxContract).balance, 0);

        // Call claimReward as owner
        vm.prank(owner);
        ethTxContract.claimReward{value: rewardAmount}(validSubmission);
        
        // Verify reward amount recorded in contract
        assertEq(ethTxContract.reward(), rewardAmount);

        // After the call, the contract should have transferred all ETH to owner, so contract balance remains 0
        assertEq(address(ethTxContract).balance, 0);
    }
    
    // Test that a non-owner calling claimReward reverts with the appropriate error message
    function testNonOwnerCannotClaimReward() public {
        uint256 rewardAmount = 1 ether;
        uint256 validSubmission = 11; // > 10

        // Expect revert with "Only owner can call claimReward"
        vm.prank(nonOwner);
        vm.expectRevert("Only owner can call claimReward");
        ethTxContract.claimReward{value: rewardAmount}(validSubmission);
    }
    
    // Test that a submission <= 10 reverts with the proper error message even when called by owner
    function testSubmissionThresholdRevert() public {
        uint256 rewardAmount = 1 ether;
        uint256 invalidSubmission = 10; // not > 10
        
        vm.prank(owner);
        vm.expectRevert("Submission must be > 10");
        ethTxContract.claimReward{value: rewardAmount}(invalidSubmission);
    }
    
    // Test that an attack attempt using AttackExploitFixed fails because non-owner cannot call claimReward
    function testAttackExploitFails() public {
        // Deploy the attack contract from nonOwner account
        vm.prank(nonOwner);
        AttackExploitFixed attacker = new AttackExploitFixed(address(ethTxContract));

        // Attempt the attack from nonOwner, expecting revert
        uint256 rewardAmount = 1 ether;
        uint256 validSubmission = 12;
        vm.prank(nonOwner);
        vm.expectRevert("Only owner can call claimReward");
        attacker.attack{value: rewardAmount}(validSubmission);
    }

    // Fallback function to receive Ether if necessary during transfers
    receive() external payable {}
}
