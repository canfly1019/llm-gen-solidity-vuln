pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The corrected contract with proper constructor initialization
contract Missing {
    // owner is set in constructor and is unmodifiable
    address payable private owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyowner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    receive() external payable {}

    // withdraw transfers the whole balance to the owner
    function withdraw() public onlyowner {
        owner.transfer(address(this).balance);
    }
}

// AttackAttempt contract that simulates an attack by trying to call a non-existent initOwner and then withdraw
contract AttackAttempt {
    Missing public target;

    constructor(address payable _target) {
        target = Missing(_target);
    }

    // Attempted attack: calls withdraw() with the hope that msg.sender is owner
    function attack() external {
        // Attempt to modify ownership would have been here but the function doesn't exist
        target.withdraw();
    }

    receive() external payable {}
}

contract MissingTest is Test {
    Missing public missing;
    address public owner;
    address public attacker;

    function setUp() public {
        // setup addresses, deposit initial state
        owner = address(0xABCD);
        attacker = address(0x1234);
        vm.startPrank(owner);
        missing = new Missing();
        vm.stopPrank();
    }

    // Test that the owner (i.e., deployer) can withdraw funds
    function testOwnerCanWithdraw() public {
        // Deposit 1 ether to the contract
        vm.deal(address(1), 1 ether);  // giving some balance to a temporary account
        // send funds to missing contract
        (bool success, ) = address(missing).call{value: 1 ether}('');
        require(success, "Deposit failed");

        // Check contract balance
        uint256 contractBalance = address(missing).balance;
        assertEq(contractBalance, 1 ether);

        // Withdraw from missing as owner
        vm.prank(owner);
        missing.withdraw();

        // After withdraw, balance of contract should be zero
        assertEq(address(missing).balance, 0);

        // Also, owner's balance should have increased. We cannot exactly assert the owner's balance because of gas usage, 
        // but we can check that the contract's 1 ether was transferred to some address using vm.expect events if needed.
        // For simplicity, we assume that if contract is empty, the transfer succeeded.
    }

    // Test that a non-owner cannot withdraw funds
    function testNonOwnerCannotWithdraw() public {
        // Deposit 1 ether to the contract
        vm.deal(address(this), 1 ether);
        (bool success, ) = address(missing).call{value: 1 ether}('');
        require(success, "Deposit failed");

        // Attempt withdrawal from attacker - expect revert with "Not owner"
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        missing.withdraw();
    }

    // Test that an attempted attack using AttackAttempt contract fails
    function testAttackAttemptFails() public {
        // Deposit 1 ether to the contract
        vm.deal(address(this), 1 ether);
        (bool success, ) = address(missing).call{value: 1 ether}('');
        require(success, "Deposit failed");

        // Deploy the AttackAttempt contract from the attacker address so that AttackAttempt's msg.sender is not the owner
        vm.prank(attacker);
        AttackAttempt attackAttempt = new AttackAttempt(payable(address(missing)));

        // Attempt attack: the attackAttempt contract will call missing.withdraw(), and should revert due to onlyowner modifier
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        attackAttempt.attack();
    }

    // Fallback function to receive ether for the test contract. Not strictly necessary since Test contract can receive ether.
    receive() external payable {}
}
