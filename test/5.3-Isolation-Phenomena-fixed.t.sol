pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.3-Isolation-Phenomena-fixed.sol";

contract IsolationFixedTest is Test {
    IsolationFixed isolationFixed;
    uint256 initialReward;

    function setUp() public {
        // Deploy the contract
        isolationFixed = new IsolationFixed();
        // Take an initial reward snapshot
        initialReward = isolationFixed.getReward();
    }

    function testFixedRewardOverBlocks() public {
        // Get the reward immediately
        uint256 rewardBefore = isolationFixed.getReward();
        
        // Move forward in time by 1000 seconds
        vm.warp(block.timestamp + 1000);

        // The reward should remain the same as calculated at deployment
        uint256 rewardAfter = isolationFixed.getReward();
        
        assertEq(rewardBefore, rewardAfter, "Reward should be consistent across blocks due to immutability of fixedBonus");
    }

    function testMultipleQueriesReturnSameValue() public {
        uint256 rewardFirst = isolationFixed.getReward();
        
        // simulate a few block progressions
        for (uint256 i = 0; i < 5; i++) {
            // advance block time by an arbitrary offset
            vm.warp(block.timestamp + 100 * (i + 1));
            uint256 currentReward = isolationFixed.getReward();
            assertEq(rewardFirst, currentReward, "All queries should return the same reward value");
        }
    }

    function testImmutableFixedBonus() public {
        // Since fixedBonus is set during construction, verify that it's logically computed from deployment block.timestamp
        // and that getReward equals baseReward + fixedBonus.
        uint256 bonus = isolationFixed.fixedBonus();
        uint256 expectedReward = isolationFixed.baseReward() + bonus;
        uint256 actualReward = isolationFixed.getReward();
        
        assertEq(expectedReward, actualReward, "getReward should equal baseReward + fixedBonus");
    }
}
