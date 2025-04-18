// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/8.1.3-Missing-verification-for-program-termination-fixed.sol";

contract FixedContractTest is Test {
    XYZ fixedContract;
    Attacker attacker;
    address nonOwner = address(0xBEEF);

    function setUp() public {
        // Deploy the fixed contract; owner will be address(this)
        fixedContract = new XYZ();
        // Fund the contract with 1 ether to test refund logic
        vm.deal(address(fixedContract), 1 ether);
    }

    function testOwnerCanDestroyAndReceiveFunds() public {
        // Record owner's balance before self-destruct
        uint256 ownerBalanceBefore = address(this).balance;
        // Owner calls destroy: should not revert and should refund 1 ether
        fixedContract.destroy();
        uint256 ownerBalanceAfter = address(this).balance;

        // Verify that the owner received the contract's balance
        assertEq(
            ownerBalanceAfter - ownerBalanceBefore,
            1 ether,
            "Owner should receive contract funds upon destroy"
        );
    }

    function testDirectNonOwnerCannotDestroy() public {
        // Simulate a call from a non-owner address
        vm.prank(nonOwner);
        // Expect revert with the require message
        vm.expectRevert("Only owner can call destroy");
        fixedContract.destroy();
    }

    function testAttackerCannotDestroyViaAttackerContract() public {
        // Deploy the Attacker contract from a non-owner address
        vm.prank(nonOwner);
        attacker = new Attacker(address(fixedContract));
        // Attempt to attack (call destroy) via the attacker contract
        vm.prank(nonOwner);
        vm.expectRevert("Only owner can call destroy");
        attacker.attack();
    }
}
