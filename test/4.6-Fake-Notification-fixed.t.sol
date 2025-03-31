pragma solidity ^0.8.0;

// Import Forge Standard Library
import "forge-std/Test.sol";

// SPDX-License-Identifier: MIT

/*
  FixedNotification Contract with vulnerability fixed
  A notification is only processed if the 'to' parameter equals to the contract's own address.
*/
contract FixedNotification {
    address public owner;

    event Notified(address indexed from, address indexed to, uint256 quantity, string memo);

    constructor() {
        owner = msg.sender;
    }

    // Only processes notification if 'to' is the contract address
    function eosponser(address from, address to, uint256 quantity, string calldata memo) public payable {
        if (to != address(this)) {
            revert("Invalid notification target");
        }
        (bool success, ) = payable(to).call{value: quantity}("");
        require(success, "Transfer failed");

        emit Notified(from, to, quantity, memo);
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}

// AttackFixed contract which simulates an attacker attempting to forge a notification
contract AttackFixed {
    FixedNotification public fixedContract;
    address public victim;

    constructor(address _fixed, address _victim) {
        fixedContract = FixedNotification(payable(_fixed));
        victim = _victim;
    }

    // This function attempts an attack by providing an invalid 'to' parameter
    function performAttack() public payable {
        require(msg.value > 0, "Send some ether");
        fixedContract.eosponser{value: msg.value}(msg.sender, victim, msg.value, "Fake notification");
    }
}

// Test contract using Foundry's Test framework
contract FixedNotificationTest is Test {
    FixedNotification fixedContract;
    address user = address(0xABCD);
    address victim = address(0xDEAD);

    event Notified(address indexed from, address indexed to, uint256 quantity, string memo);

    function setUp() public {
        // Deploy FixedNotification contract
        fixedContract = new FixedNotification();
        // Fund the test contract with some Ether
        vm.deal(address(this), 10 ether);
    }

    // Test that a valid notification (with to == address(this)) is processed correctly
    function testValidNotification() public {
        uint256 sendAmount = 1 ether;
        // Starting balance of contract (should be 0, but will increase by self-call transfer)
        uint256 initialBalance = address(fixedContract).balance;

        // Expect the Notified event
        vm.expectEmit(true, true, true, true);
        emit Notified(user, address(fixedContract), sendAmount, "Valid notification");

        // Call eosponser with correct target (address(this) of FixedNotification)
        // We simulate as if user is sending the notification: we use user as 'from'
        // But since function is not restricted by msg.sender, it uses the provided param values
        fixedContract.eosponser{value: sendAmount}(user, address(fixedContract), sendAmount, "Valid notification");

        // Check that the transfer in the contract succeeded. Because the call sends the funds to itself,
        // its balance should increase by sendAmount from this call.
        uint256 finalBalance = address(fixedContract).balance;
        assertEq(finalBalance - initialBalance, sendAmount);
    }

    // Test that an attack using a forged notification is reverted, preventing malicious use
    function testAttackFails() public {
        uint256 sendAmount = 1 ether;
        // Deploy the AttackFixed contract with victim address not equal to fixedContract address
        AttackFixed attack = new AttackFixed(address(fixedContract), victim);

        // Expect revert with the specific error message
        vm.expectRevert(bytes("Invalid notification target"));
        // Attempt attack: performAttack will call eosponser with victim as the target, which should revert
        attack.performAttack{value: sendAmount}();
    }

    // Additional test: Direct call by an attacker using forged notification parameters directly to FixedNotification
    function testDirectForgedNotificationFails() public {
        uint256 sendAmount = 0.5 ether;

        // Expect revert with the specific error message
        vm.expectRevert(bytes("Invalid notification target"));
        // Call eosponser with to parameter not equal to address(this)
        fixedContract.eosponser{value: sendAmount}(user, victim, sendAmount, "Forged direct notification");
    }
}
