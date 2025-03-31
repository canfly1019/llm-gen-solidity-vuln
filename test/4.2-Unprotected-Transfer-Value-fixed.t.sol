pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "forge-std/Test.sol";

// Import the contracts under test

contract MultiOwnable {
    mapping(address => bool) public owners;

    constructor() {
        owners[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(owners[msg.sender], "Not owner");
        _;
    }

    function newOwner(address _owner) external onlyOwner returns (bool) {
        require(_owner != address(0), "Invalid owner address");
        owners[_owner] = true;
        return true;
    }
}

contract TestContract is MultiOwnable {
    // Allow owner to withdraw all funds
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Accept Ether
    receive() external payable {}
}

contract AttackFixed {
    TestContract public fixedContract;

    constructor(address _fixedContract) {
        fixedContract = TestContract(payable(_fixedContract));
    }

    function attack() public {
        // Attempt to add msg.sender as owner. Will revert since caller is not an owner.
        fixedContract.newOwner(msg.sender);
        // Attempt to withdraw funds. Will revert due to onlyOwner modifier.
        fixedContract.withdrawAll();
    }

    receive() external payable {}
}

contract FixedTransferTest is Test {
    TestContract testContract;
    AttackFixed attackContract;
    address owner = address(0xABCD);
    address attacker = address(0xBEEF);

    // Set up the test environment
    function setUp() public {
        // Deploy the TestContract with owner as msg.sender
        vm.prank(owner);
        testContract = new TestContract();

        // Fund the testContract with some Ether
        vm.deal(address(testContract), 10 ether);
    }

    // Test that a non-owner cannot add a new owner using newOwner() function
    function testNewOwnerRevertForNonOwner() public {
        // Ensure attacker is not an owner
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        testContract.newOwner(attacker);
    }

    // Test that a non-owner cannot withdraw funds
    function testWithdrawAllRevertForNonOwner() public {
        // Attempt to withdraw with non-owner account
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        testContract.withdrawAll();
    }

    // Test that the legitimate owner can add a new owner and withdraw funds
    function testOwnerCanAddNewOwnerAndWithdraw() public {
        // Legitimate owner adds attacker as a new owner
        vm.prank(owner);
        bool success = testContract.newOwner(attacker);
        assertTrue(success, "newOwner did not succeed");
        
        // Verify that attacker is now an owner
        bool isOwner = testContract.owners(attacker);
        assertTrue(isOwner, "attacker should now be owner");

        // Check withdrawAll works for the new owner
        uint256 initialBalance = attacker.balance;
        vm.prank(attacker);
        testContract.withdrawAll();

        // Since 10 ether was in testContract, attacker's balance should have increased by ~10 ether
        uint256 delta = attacker.balance - initialBalance;
        assertEq(delta, 10 ether, "attacker did not receive correct amount");
    }

    // Test that an attack attempt via AttackFixed contract fails
    function testAttackFixedFailsToExploitOwnership() public {
        // Deploy the AttackFixed contract from attacker account
        vm.prank(attacker);
        attackContract = new AttackFixed(address(testContract));
        
        // Attempt the attack.
        // Since AttackFixed.attack() calls newOwner, which should revert due to not being an owner,
        // we expect an error.
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        attackContract.attack();
    }
}
