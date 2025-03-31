pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Include the contract definitions

// SPDX-License-Identifier: UNLICENSED

contract Missing {
    address payable private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}

contract Attack {
    Missing public fixedContract;

    constructor(address payable _fixedAddress) {
        fixedContract = Missing(_fixedAddress);
    }

    function attack() external {
        // There is no callable constructor function. Attack fails.
        // Attempted call to non-existent constructor function is commented out.
        // fixedContract.Constructor();
    }

    receive() external payable {}
}

contract MissingTest is Test {
    Missing public missingContract;
    Attack public attackContract;
    address public owner;
    address public attacker;

    function setUp() public {
        owner = address(0xABCD);
        attacker = address(0xBEEF);
        // Deploy Missing contract with owner as the deployer
        vm.startPrank(owner);
        missingContract = new Missing();
        vm.deal(owner, 100 ether);
        // Send some Ether to missingContract to simulate funds
        (bool success, ) = address(missingContract).call{value: 10 ether}("");
        require(success, "Failed to fund missingContract");
        vm.stopPrank();
    }

    function testOnlyOwnerCanWithdraw() public {
        // Attempt withdrawal from non-owner, expect revert with "Not owner"
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        missingContract.withdraw();

        // Now, withdraw using the owner
        uint ownerBalanceBefore = owner.balance;
        vm.prank(owner);
        missingContract.withdraw();
        // After withdrawal, missing contract balance should be 0
        assertEq(address(missingContract).balance, 0);
        // Owner's balance should have increased by ~10 ether (minus gas), check at least greater than before
        assertGt(owner.balance, ownerBalanceBefore);
    }

    function testAttackCannotStealOwnership() public {
        // Deploy the attack contract from attacker account
        vm.prank(attacker);
        attackContract = new Attack(payable(address(missingContract)));

        // Call the attack function. Even though attack() exists, it cannot change ownership.
        vm.prank(attacker);
        attackContract.attack();

        // After calling attack, the non-owner (attacker) still should not be able to withdraw.
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        missingContract.withdraw();

        // Owner still should be able to withdraw funds.
        uint ownerBalanceBefore = owner.balance;
        vm.prank(owner);
        missingContract.withdraw();
        assertEq(address(missingContract).balance, 0);
        assertGt(owner.balance, ownerBalanceBefore);
    }

    // Additional test: Ensure that there is no callable function that can reset the owner
    function testNoConstructorFunctionCallable() public {
        // Since constructor is only callable once at deployment, try calling a non-existing function signature
        // that attacker might try to use to hijack ownership. We simulate this by using low-level call with an invalid selector.
        bytes4 fakeConstructorSelector = bytes4(keccak256("Constructor()"));
        vm.prank(attacker);
        (bool success, ) = address(missingContract).call(abi.encodeWithSelector(fakeConstructorSelector));
        // The call should succeed (if fallback exists) but do nothing, or simply fail. But importantly, owner is unchanged.
        // In this contract, no fallback exists so success == false.
        assertTrue(!success, "Fake constructor call should not succeed");

        // Now verify that owner withdrawal still only works with owner
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        missingContract.withdraw();
    }

    // helper function to send Ether from the test contract
    receive() external payable {}
}
