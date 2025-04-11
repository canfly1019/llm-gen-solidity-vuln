pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/8.1.1-Wrong-Caller-Identification-fixed.sol";

contract FixedUserWalletTest is Test {
    FixedUserWallet wallet;
    AttackWalletFixed attack;
    address nonOwner;
    address payable thief;
    uint256 constant INITIAL_BALANCE = 1 ether;

    function setUp() public {
        // Set up nonOwner and thief addresses using cheat codes
        nonOwner = vm.addr(1);
        thief = payable(vm.addr(2));

        // Deploy FixedUserWallet with an initial balance; msg.sender becomes the owner
        wallet = new FixedUserWallet{value: INITIAL_BALANCE}();

        // Deploy the attacker contract, providing the wallet address and a designated thief address
        attack = new AttackWalletFixed(payable(address(wallet)), thief);
    }

    function testOwnerCanTransfer() public {
        uint256 transferAmount = 0.5 ether;
        uint256 initialThiefBalance = thief.balance;

        // As owner (this contract is the owner), call transfer to send Ether to thief
        wallet.transfer(thief, transferAmount);

        // Validate that thief has received the correct amount
        assertEq(thief.balance, initialThiefBalance + transferAmount, "Destination should receive correct amount");
    }

    function testNonOwnerDirectCallFails() public {
        uint256 transferAmount = 0.1 ether;

        // Use vm.prank to simulate a call from a non-owner
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Not owner"));
        wallet.transfer(thief, transferAmount);
    }

    function testAttackFailsUsingIntermediary() public {
        // Capture the wallet's balance before the attack
        uint256 walletBalanceBefore = address(wallet).balance;

        // To trigger the fallback in AttackWalletFixed (and not the receive function), we include non-empty calldata
        // Send 0.1 ether to the attack contract so that it holds a balance, which it then attempts to transfer
        vm.expectRevert(bytes("Not owner"));
        (bool success, ) = address(attack).call{value: 0.1 ether}(abi.encodeWithSignature("nonExistent()"));

        // Although vm.expectRevert handles the expected revert, we verify that the attack did not succeed
        // Confirm that the wallet's balance remains unchanged
        assertEq(address(wallet).balance, walletBalanceBefore, "Wallet balance should remain unchanged");

        // Confirm that the thief has not received any funds
        assertEq(thief.balance, 0, "Thief should not receive any funds");
    }
}
