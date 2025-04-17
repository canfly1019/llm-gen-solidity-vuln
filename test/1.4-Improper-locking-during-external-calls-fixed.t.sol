// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/1.4-Improper-locking-during-external-calls-fixed.sol";

contract BidFixedTest is Test {
    BidFixed bid;
    // 本來 LLM 產生的 user 是 address(0x1)，但 0x1~0x9 是 forge-std 的預編譯合約地址，所以改成 address(0x1234)
    address user = address(0x1234);

    function setUp() public {
        bid = new BidFixed();
        // Give user some ETH
        vm.deal(user, 10 ether);
    }

    // Test that withdraw reverts when there are no pending funds
    function testWithdrawNoPending() public {
        vm.prank(user);
        vm.expectRevert("No pending funds");
        bid.withdraw();
    }

    // Test that withdraw reverts if the contract state is locked
    function testWithdrawWhenLocked() public {
        // Manually set state to InTransition (enum value 1) via storage slot 0
        vm.store(address(bid), bytes32(uint256(0)), bytes32(uint256(1)));
        vm.prank(user);
        vm.expectRevert("Contract is in transition, try again later");
        bid.withdraw();
    }

    // Test a successful withdraw flow
    function testSuccessfulWithdraw() public {
        // Prepare: set pendingReturns[user] = 1 ether in storage (mapping at slot 2)
        
        bytes32 mappingSlot = keccak256(
            abi.encodePacked(
                bytes32(uint256(uint160(user))),
                // LLM 本來產生的 mappingSlot 是 3，而實際上這個 mapping 的槽號是 2。這是因為 Solidity 會把前兩個小型變數（enum state 和 address highestBidder）打包進第 0 號槽，然後把 highestBid 放在槽 1，接著才是 pendingReturns 的槽 2。所以改成 2
                bytes32(uint256(2))
            )
        );
        vm.store(address(bid), mappingSlot, bytes32(uint256(1 ether)));
        // Fund the contract so that transfer will succeed
        vm.deal(address(bid), 1 ether);

        // Record user's balance before withdraw
        uint256 balBefore = user.balance;

        // Perform withdraw
        vm.prank(user);
        bid.withdraw();

        // Check that the user received exactly 1 ether
        assertEq(user.balance - balBefore, 1 ether);

        // Check that pendingReturns was cleared
        uint256 pending = bid.pendingReturns(user);
        assertEq(pending, 0);

        // Check the contract state is unlocked (State.F == 0)
        assertEq(uint256(bid.state()), uint256(BidFixed.State.F));
    }
}
