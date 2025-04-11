pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/6.1.6-Transfer-Recipient-Depending-on-Transaction-Order-fixed.sol";

// We will create two helper contracts to simulate the behavior of the walletLibrary:
// 1. MockWalletLibrary: A working implementation that, via delegatecall, sends the entire balance from the Wallet to the caller.
// 2. FailingWalletLibrary: An implementation that reverts, forcing delegatecall to fail.

contract MockWalletLibrary {
    // fallback function (and receive) to handle all calls and send the entire balance of the Wallet (i.e. address(this)) to msg.sender
    fallback() external payable {
        // In a delegatecall, address(this) corresponds to the Wallet contract.
        uint256 bal = address(this).balance;
        // Transfer all funds from the Wallet to the caller.
        (bool sent, ) = payable(msg.sender).call{value: bal} ("");
        require(sent, "Transfer failed");
    }

    receive() external payable {
        // Also support plain ETH transfers.
        uint256 bal = address(this).balance;
        (bool sent, ) = payable(msg.sender).call{value: bal} ("");
        require(sent, "Transfer failed");
    }
}

contract FailingWalletLibrary {
    // fallback function that always reverts
    fallback() external payable {
        revert("fail");
    }

    receive() external payable {
        revert("fail");
    }
}

contract WalletTest is Test {
    // The Wallet contract uses a constant walletLibrary address
    // 0xb794F5eA0ba39494cE839613fffBA74279579268
    address constant LIB_ADDRESS = 0xb794F5eA0ba39494cE839613fffBA74279579268;

    Wallet wallet;

    // Test: When the delegatecall target reverts (via FailingWalletLibrary), withdraw should revert with "Delegatecall failed".
    function testWithdrawRevertsOnDelegatecallFailure() public {
        // Deploy a failing library instance and override the code at LIB_ADDRESS with its runtime code.
        FailingWalletLibrary failing = new FailingWalletLibrary();
        // vm.etch sets the code at the given address
        vm.etch(LIB_ADDRESS, address(failing).code);

        wallet = new Wallet();

        // Fund the Wallet with 1 ether
        uint256 deposit = 1 ether;
        vm.deal(address(wallet), deposit);

        // Expect the call to revert because delegatecall should fail and then trigger require
        vm.expectRevert(bytes("Delegatecall failed"));
        wallet.withdraw();
    }

    // Test: With a working library (MockWalletLibrary), withdraw should transfer all funds from the Wallet to the caller
    function testWithdrawSendsFundsToCaller() public {
        // Deploy the working library and override the code at LIB_ADDRESS
        MockWalletLibrary mockLib = new MockWalletLibrary();
        vm.etch(LIB_ADDRESS, address(mockLib).code);

        wallet = new Wallet();
        uint256 deposit = 10 ether;
        // Set the wallet's balance
        vm.deal(address(wallet), deposit);

        // For a clearer test, we use an external address as the caller
        address caller = address(0x123);
        uint256 callerInitialBalance = caller.balance;

        vm.prank(caller);
        wallet.withdraw();

        // Wallet balance should be 0 after withdrawal
        assertEq(address(wallet).balance, 0, "Wallet balance should be zero after withdraw");
        // Caller should receive the deposited funds
        assertEq(caller.balance, callerInitialBalance + deposit, "Caller should receive the withdrawn funds");
    }

    // Test: Withdraw works correctly for different users using separate Wallet instances
    function testWithdrawWorksForDifferentUsers() public {
        // Deploy the working library and override the code at LIB_ADDRESS
        MockWalletLibrary mockLib = new MockWalletLibrary();
        vm.etch(LIB_ADDRESS, address(mockLib).code);

        // Deploy two separate Wallet contracts
        Wallet walletA = new Wallet();
        Wallet walletB = new Wallet();

        uint256 depositA = 5 ether;
        uint256 depositB = 3 ether;
        vm.deal(address(walletA), depositA);
        vm.deal(address(walletB), depositB);

        // Use two different users
        address user1 = address(0x111);
        address user2 = address(0x222);
        uint256 user1Initial = user1.balance;
        uint256 user2Initial = user2.balance;

        vm.prank(user1);
        walletA.withdraw();
        assertEq(address(walletA).balance, 0, "walletA should be empty after withdraw");
        assertEq(user1.balance, user1Initial + depositA, "User1 should receive depositA");

        vm.prank(user2);
        walletB.withdraw();
        assertEq(address(walletB).balance, 0, "walletB should be empty after withdraw");
        assertEq(user2.balance, user2Initial + depositB, "User2 should receive depositB");
    }
}
