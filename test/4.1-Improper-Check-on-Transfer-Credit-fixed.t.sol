pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The provided SimpleBankFixed contract
contract SimpleBankFixed {
    mapping(address => uint) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint amount = balances[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: amount}('');
        require(success, "Transfer failed");
        balances[msg.sender] = 0;
    }
}

// NormalReceiver: accepts ETH normally
contract NormalReceiver {
    fallback() external payable {}
    receive() external payable {}
}

// RevertingReceiver: designed to always revert on receiving ETH
contract RevertingReceiver {
    // This fallback function will revert any ETH transfer
    fallback() external payable {
        revert("I do not accept ETH");
    }
    
    // Also revert in receive
    receive() external payable {
        revert("I do not accept ETH");
    }

    // Helper function to deposit ETH into a SimpleBankFixed contract
    function deposit(address bank) external payable {
        // Forward the deposit call along with msg.value
        (bool success, ) = bank.call{value: msg.value}(abi.encodeWithSignature("deposit()"));
        require(success, "Deposit failed");
    }

    // Helper function to trigger withdrawal from SimpleBankFixed contract
    function withdraw(address bank) external {
        (bool success, ) = bank.call(abi.encodeWithSignature("withdraw()"));
        // We forward the success flag, but note that if the transfer fails, this should revert.
        require(success, "Withdrawal failed in attacker contract");
    }
}

contract SimpleBankFixedTest is Test {
    SimpleBankFixed bank;
    NormalReceiver normalReceiver;
    RevertingReceiver revertingReceiver;

    address user = address(1);
    uint256 depositAmount = 1 ether;

    function setUp() public {
        bank = new SimpleBankFixed();
        normalReceiver = new NormalReceiver();
        revertingReceiver = new RevertingReceiver();
        // In Foundry tests, we need to fund the user accounts
        vm.deal(user, 10 ether);
        vm.deal(address(revertingReceiver), 10 ether);
    }

    // Test that a normal user can deposit and withdraw successfully
    function testSuccessfulWithdraw() public {
        // Deposit from user
        vm.prank(user);
        bank.deposit{value: depositAmount}();

        // Confirm that the balance is recorded
        uint256 recordedBalance = bank.balances(user);
        assertEq(recordedBalance, depositAmount, "Deposit amount not recorded correctly");

        // Record user ETH balance before withdrawal
        uint256 userBalanceBefore = user.balance;

        // Withdraw as user
        vm.prank(user);
        bank.withdraw();

        // After withdrawal, the user's bank balance should be zero
        uint256 recordedAfter = bank.balances(user);
        assertEq(recordedAfter, 0, "User balance was not reset after withdrawal");

        // Check that user received the ETH. Due to gas costs, use approximation (balance increased by depositAmount)
        uint256 userBalanceAfter = user.balance;
        assertApproxEqAbs(userBalanceAfter, userBalanceBefore + depositAmount, 0, "User did not receive the correct funds");
    }

    // Test that withdrawal reverts if the receiving contract rejects ETH
    function testWithdrawRevertsForRevertingReceiver() public {
        // Using the attacker contract (RevertingReceiver) to deposit
        uint256 attackerDeposit = depositAmount;
        // From the context of revertingReceiver, deposit into bank
        vm.prank(address(revertingReceiver));
        // We need to call the deposit() function of bank from the RevertingReceiver account
        bank.deposit{value: attackerDeposit}();

        // Check that bank recorded the deposit under the revertingReceiver's address
        uint256 recordedBalance = bank.balances(address(revertingReceiver));
        assertEq(recordedBalance, attackerDeposit, "Deposit amount not recorded correctly for RevertingReceiver");

        // Attempt withdrawal: this should revert because the RevertingReceiver will reject the ETH
        vm.prank(address(revertingReceiver));
        vm.expectRevert(bytes("Transfer failed"));
        bank.withdraw();

        // After the failed withdrawal, the balance should remain unchanged
        uint256 balanceAfterFailedWithdraw = bank.balances(address(revertingReceiver));
        assertEq(balanceAfterFailedWithdraw, attackerDeposit, "Balance should not be reset on failed transfer");
    }

    // Additionally, test that a normal receiver contract can successfully withdraw funds if it was set as the msg.sender
    // To simulate this, we'll simulate the withdrawal by making the NormalReceiver call withdraw()
    function testWithdrawSucceedsForNormalReceiver() public {
        // Fund the NormalReceiver by impersonating its address
        vm.deal(address(normalReceiver), 10 ether);

        // From NormalReceiver's perspective, deposit funds
        vm.prank(address(normalReceiver));
        bank.deposit{value: depositAmount}();

        uint256 recordedBalance = bank.balances(address(normalReceiver));
        assertEq(recordedBalance, depositAmount, "Deposit amount not recorded correctly for NormalReceiver");

        // Record NormalReceiver's balance before withdrawal
        uint256 balanceBefore = address(normalReceiver).balance;

        // From NormalReceiver, call withdraw
        vm.prank(address(normalReceiver));
        bank.withdraw();

        // The balance mapping should now be zero
        uint256 recordedAfter = bank.balances(address(normalReceiver));
        assertEq(recordedAfter, 0, "NormalReceiver balance was not reset after withdrawal");

        // NormalReceiver should have received the depositAmount. Using approximation check.
        uint256 balanceAfter = address(normalReceiver).balance;
        assertApproxEqAbs(balanceAfter, balanceBefore + depositAmount, 0, "NormalReceiver did not receive correct funds");
    }
}
