pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Contract under test
contract FixedContract {
    address public owner;

    // Correct modifier that checks msg.sender
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Only owner can withdraw the ether
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Receive function to accept ether
    receive() external payable {}
}

// Attack contract trying to bypass modifier restrictions
contract AttackFixed {
    FixedContract public fixedContract;

    constructor(address payable _fixedContractAddress) {
        fixedContract = FixedContract(_fixedContractAddress);
    }

    // Attempt to call withdraw()
    function attack() public {
        fixedContract.withdraw();
    }

    // Receive funds
    receive() external payable {}
}

// Foundry test contract
contract ImproperModifierTest is Test {
    FixedContract fixedContract;
    address owner;
    address attacker;

    // Deploy contracts and set accounts
    function setUp() public {
        // Set test addresses
        owner = address(0xBEEF);
        attacker = address(0xDEAD);

        // Label addresses for easier debugging
        vm.label(owner, "Owner");
        vm.label(attacker, "Attacker");

        // Deploy FixedContract as owner using vm.prank
        vm.prank(owner);
        fixedContract = new FixedContract();

        // Provide both accounts with some ether
        vm.deal(owner, 100 ether);
        vm.deal(attacker, 100 ether);
    }

    // Test that the owner can successfully withdraw funds
    function testOwnerCanWithdraw() public {
        uint256 depositAmount = 10 ether;

        // Deposit funds to the FixedContract from the owner address
        vm.prank(owner);
        (bool success, ) = address(fixedContract).call{value: depositAmount}(
            ""
        );
        require(success, "Deposit failed");

        // Pre-withdrawal balance check
        uint256 contractBalance = address(fixedContract).balance;
        assertEq(contractBalance, depositAmount, "Incorrect contract balance before withdraw");

        // Owner calls withdraw
        vm.prank(owner);
        fixedContract.withdraw();

        // Post-withdrawal contract balance should be zero
        assertEq(address(fixedContract).balance, 0, "Contract balance not zero after withdraw");
    }

    // Test that a non-owner cannot withdraw funds
    function testNonOwnerCannotWithdraw() public {
        uint256 depositAmount = 5 ether;

        // Deposit funds to the FixedContract from the owner address
        vm.prank(owner);
        (bool success, ) = address(fixedContract).call{value: depositAmount}(""
        );
        require(success, "Deposit failed");

        // Attempt withdraw as attacker should revert
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner!"));
        fixedContract.withdraw();
    }

    // Test that an attack contract (deployed by a non-owner) cannot successfully withdraw funds
    function testAttackContractCannotWithdraw() public {
        uint256 depositAmount = 3 ether;

        // Deposit funds from the owner
        vm.prank(owner);
        (bool success, ) = address(fixedContract).call{value: depositAmount}(""
        );
        require(success, "Deposit failed");

        // Deploy AttackFixed from the attacker address to simulate an attack.
        vm.prank(attacker);
        AttackFixed attackContract = new AttackFixed(payable(address(fixedContract)));

        // The attack function should revert because AttackFixed is not the owner
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner!"));
        attackContract.attack();
    }
}
