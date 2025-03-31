pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// BugFixed contract with fixed variable shadowing issue
contract BugFixed {
    // State variable stores the contract owner
    address public owner;

    // Set the owner to the deployer
    constructor() {
        owner = msg.sender;
    }

    // sensitive_function: only owner can call this function
    function sensitive_function() public {
        require(owner == msg.sender, "Not authorized");
        // Sensitive operation would occur here
    }

    // alternate_sensitive_function uses a local variable which does not conflict with the state variable
    function alternate_sensitive_function() public {
        address localOwner = msg.sender;
        require(localOwner == msg.sender, "Not authorized");
        // Other logic follows
    }
}

// Attack contract attempting to call sensitive_function
contract AttackFixed {
    BugFixed public fixedBug;

    // Pass in the address of BugFixed during deployment
    constructor(address _fixedBugAddress) {
        fixedBug = BugFixed(_fixedBugAddress);
    }

    // The attack process: attempt to exploit sensitive_function
    function attack() public {
        fixedBug.sensitive_function();
    }
}

contract BugFixedTest is Test {
    BugFixed public bugFixed;
    AttackFixed public attackFixed;
    address public nonOwner = address(0xBEEF);

    function setUp() public {
        // Deploy BugFixed with the default test contract as the owner
        bugFixed = new BugFixed();
    }

    // Test that the owner can successfully call sensitive_function
    function testOwnerCanCallSensitiveFunction() public {
        // msg.sender is the deployer and thus should be the owner
        bugFixed.sensitive_function();
        // If no revert, then the test passes
    }

    // Test that non-owners cannot call the sensitive_function
    function testNonOwnerCannotCallSensitiveFunction() public {
        vm.prank(nonOwner);
        vm.expectRevert("Not authorized");
        bugFixed.sensitive_function();
    }

    // Test that alternate_sensitive_function works for any caller, since the check is local
    function testAlternateSensitiveFunctionAnyCaller() public {
        vm.prank(nonOwner);
        // This call should succeed because localOwner is set to msg.sender
        bugFixed.alternate_sensitive_function();
    }

    // Test the AttackFixed contract to confirm that an attacker cannot bypass the owner check
    function testAttackRevert() public {
        // Deploy the AttackFixed contract from a non-owner account
        vm.prank(nonOwner);
        attackFixed = new AttackFixed(address(bugFixed));

        // Attempt the attack from the non-owner account
        vm.prank(nonOwner);
        vm.expectRevert("Not authorized");
        attackFixed.attack();
    }
}
