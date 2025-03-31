pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Include the FixedWallet and AttackFixed contracts

contract FixedWallet {
    mapping(address => uint256) public userBalances;

    function deposit() external payable {
        userBalances[msg.sender] += msg.value;
    }

    function withdrawBalance() public {
        uint256 amountToWithdraw = userBalances[msg.sender];
        require(amountToWithdraw > 0, "No balance to withdraw");

        // Update state before transfer
        userBalances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
    fallback() external payable {}
}

contract AttackFixed {
    FixedWallet public fixedWallet;
    address public owner;
    uint256 public count;

    constructor(address payable _fixedWalletAddress) {
        fixedWallet = FixedWallet(_fixedWalletAddress);
        owner = msg.sender;
    }

    // Attack entry point: deposit and then try withdraw
    function attack() external payable {
        require(msg.sender == owner, "Not owner");
        fixedWallet.deposit{value: msg.value}();
        fixedWallet.withdrawBalance();
    }

    // Fallback function triggered on receiving Ether
    fallback() external payable {
        if (count < 2) {
            count++;
            // Attempt reentrancy - this should fail because the balance is already set to 0
            fixedWallet.withdrawBalance();
        }
    }

    // Function for owner to collect funds from this contract
    function collectEther() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}

contract FixedWalletTest is Test {
    FixedWallet wallet;
    address user = address(0xABCD);

    // We'll use an attacker address for the AttackFixed contract
    address attackerEOA = address(0xBEEF);
    AttackFixed attacker;

    // Set up before each test
    function setUp() public {
        // Deploy the FixedWallet contract
        wallet = new FixedWallet();

        // Label addresses for clarity
        vm.label(user, "User");
        vm.label(attackerEOA, "AttackerEOA");
        vm.label(address(wallet), "FixedWallet");

        // Deploy the AttackFixed contract as the attacker
        // Use vm.prank so that attackerEOA is the msg.sender for the constructor
        vm.prank(attackerEOA);
        attacker = new AttackFixed(payable(address(wallet)));
    }

    // Test that a normal user can deposit and withdraw funds correctly
    function testNormalWithdrawal() public {
        uint256 depositAmount = 1 ether;

        // Use 'user' address to deposit
        vm.deal(user, depositAmount);
        vm.prank(user);
        wallet.deposit{value: depositAmount}();

        // Check that storage is updated
        uint256 balanceStored = wallet.userBalances(user);
        assertEq(balanceStored, depositAmount, "User balance should be updated after deposit");

        // Withdraw funds
        vm.prank(user);
        wallet.withdrawBalance();

        // After withdrawal, the user's stored balance should be zero
        balanceStored = wallet.userBalances(user);
        assertEq(balanceStored, 0, "User balance should be zero after withdrawal");
        
        // Check that the user received the Ether. Since we cannot catch the EVM balance directly from vm, we simulate it.
        // For testing, we can check that the contract balance of FixedWallet is reduced by depositAmount.
        uint256 walletEthBalance = address(wallet).balance;
        // The wallet contract might have received Ether from deposit, then sent Ether via withdrawal, so its balance should be 0
        assertEq(walletEthBalance, 0, "Wallet should be drained after withdrawal");
    }

    // Test the reentrancy attack attempt using the AttackFixed contract
    function testReentrancyAttackFails() public {
        uint256 depositAmount = 1 ether;
        vm.deal(attackerEOA, depositAmount);

        // Expect the reentrant call to fail with "Transfer failed"
        // Since the attack contract's fallback will attempt to reenter the wallet, and due to fixed state ordering the reentrant call reverts,
        // the overall attack() call should revert with "Transfer failed".
        vm.prank(attackerEOA);
        vm.expectRevert(bytes("Transfer failed"));
        attacker.attack{value: depositAmount}();

        // Ensure that no funds were erroneously transferred to attacker contract
        // Check that the wallet still holds no balance for the attacker (since the transaction reverted and state is unchanged)
        uint256 attackerStoredBalance = wallet.userBalances(address(attacker));
        assertEq(attackerStoredBalance, 0, "Attacker balance in wallet should be zero after failed attack");
    }
}
