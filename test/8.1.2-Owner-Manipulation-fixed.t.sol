pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/8.1.2-Owner-Manipulation-fixed.sol";

contract OwnerManipulationTest is Test {
    FixedHOTTO target;
    AttackerFixed attackerContract;

    // The fixed owner address in the FixedHOTTO contract
    address fixedOwner = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    
    // Use an arbitrary attacker address
    address attacker = address(0xABCD);

    function setUp() public {
        // Deploy the target contract
        target = new FixedHOTTO();

        // Deploy the attacker contract from the attacker address
        vm.prank(attacker);
        attackerContract = new AttackerFixed(address(target));
    }

    function testHTDistributesTokensToFixedOwner() public {
        // Before calling HT, fixed owner's token balance should be 0
        uint256 initialBalance = target.balances(fixedOwner);
        assertEq(initialBalance, 0, "Initial token balance of fixed owner should be 0");

        // Call HT from any address; note that HT is not restricted by onlyOwner
        target.HT();

        // After calling HT, fixed owner should receive totalDistributed tokens (i.e., 1000)
        uint256 postBalance = target.balances(fixedOwner);
        assertEq(postBalance, target.totalDistributed(), "Fixed owner's token balance should equal totalDistributed");
    }

    function testWithdrawByFixedOwnerSucceeds() public {
        // Fund the contract with some Ether to withdraw
        uint256 depositAmount = 1 ether;
        payable(address(target)).transfer(depositAmount);

        // Check contract balance
        assertEq(address(target).balance, depositAmount, "Contract should have depositAmount Ether");

        // Withdraw as fixedOwner; we use vm.prank to simulate that the call is coming from fixed owner
        vm.prank(fixedOwner);
        target.withdraw();

        // After withdraw, contract balance should be 0
        assertEq(address(target).balance, 0, "Contract balance should be 0 after withdrawal");
    }

    function testWithdrawByAttackerFails() public {
        // Fund the contract with Ether
        uint256 depositAmount = 1 ether;
        payable(address(target)).transfer(depositAmount);

        // Attempt to withdraw using the attacker contract's attack() function
        // Expect revert because the withdraw() will fail due to onlyOwner check
        vm.prank(attacker);
        vm.expectRevert("NOT OWNER");
        attackerContract.attack();
    }

    // Fallback payable function to accept Ether when testing transfers
    receive() external payable {}
}
