pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// SPDX-License-Identifier: UNLICENSED

// The FixedContract with proper initialization protection
contract FixedContract {
    address public owner;
    bool private initialized; // initialization flag to prevent reinitialization

    // For upgradeable contracts, using initialize(), but with protection against reinitialization
    function initialize() public {
        require(!initialized, "Already initialized");
        owner = msg.sender;
        initialized = true;
    }

    // Allow deposits
    function deposit() public payable {}

    // Only owner can withdraw
    function withdraw() public {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }

    // receive Ether
    receive() external payable {}
}


contract FixedContractTest is Test {
    FixedContract public fixedContract;
    address public owner = address(0xABCD);
    address public attacker = address(0xBEEF);

    function setUp() public {
        // Deploy the contract from the owner address
        vm.prank(owner);
        fixedContract = new FixedContract();
    }

    // Test that initialize can be called once successfully
    function testInitializeSucceeds() public {
        vm.prank(owner);
        fixedContract.initialize();
        assertEq(fixedContract.owner(), owner, "Owner should be set to the initializer");
    }

    // Test that calling initialize a second time reverts.
    function testCannotReinitialize() public {
        // First initialization from owner
        vm.prank(owner);
        fixedContract.initialize();

        // Attempt to call initialize again from owner and check for revert
        vm.prank(owner);
        vm.expectRevert(bytes("Already initialized"));
        fixedContract.initialize();
    }

    // Test that a non-owner cannot initialize the contract once it's initialized.
    function testAttackReinitializeFails() public {
        // Owner initializes
        vm.prank(owner);
        fixedContract.initialize();

        // Attacker tries to initialize again
        vm.prank(attacker);
        vm.expectRevert(bytes("Already initialized"));
        fixedContract.initialize();
    }

    // Additionally, test that only the owner can withdraw funds after initialization
    function testWithdrawOnlyOwner() public {
        // Initialize as owner
        vm.prank(owner);
        fixedContract.initialize();

        // Deposit some Ether into the contract
        vm.deal(attacker, 10 ether);
        vm.prank(attacker);
        fixedContract.deposit{value: 1 ether}();

        // Attempt withdrawal from attacker and expect revert
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        fixedContract.withdraw();

        // Withdraw as owner, should succeed
        uint256 initialBalance = owner.balance;
        vm.prank(owner);
        fixedContract.withdraw();
        // Using deal to mimic balance changes is not tracked by EVM sometimes but we check contract balance is now zero
        assertEq(address(fixedContract).balance, 0, "Contract balance should be zero after withdrawal");
    }
}
