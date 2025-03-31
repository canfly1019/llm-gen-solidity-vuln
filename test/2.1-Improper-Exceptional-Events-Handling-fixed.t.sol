pragma solidity ^0.8.0;

import "forge-std/Test.sol";
// Import the FixedContract and AttackContractFixed from the source file
import "../src/2.1-Improper-Exceptional-Events-Handling-fixed.sol";

contract FixedContractTest is Test {
    FixedContract fixedContract;
    AttackContractFixed attacker;

    // Setup deploys a new FixedContract and a new AttackContractFixed
    function setUp() public {
        fixedContract = new FixedContract();
        attacker = new AttackContractFixed(payable(address(fixedContract)));
    }

    // Test that an attack using AttackContractFixed fails due to fallback reversion, ensuring atomicity.
    function testAttackFails() public {
        uint attackValue = 1 ether;
        // Fund the test contract
        vm.deal(address(this), 10 ether);

        // Expect that the withdrawal in FixedContract will revert due to the fallback in AttackContractFixed
        vm.expectRevert("Transfer failed");
        // When calling attack, deposit is made then the withdraw is attempted; the withdraw will revert as
        // the low-level call to AttackContractFixed.fallback() fails.
        attacker.attack{value: attackValue}();

        // Verify that the state has not been altered by the failed transaction
        // The deposit should have been reverted, and thus the balance for the attacker remains 0.
        assertEq(fixedContract.balances(address(attacker)), 0);
        // Also, the FixedContract should not have kept any Ether from the failed attack attempt
        assertEq(address(fixedContract).balance, 0);
    }

    // Test a legitimate deposit and withdrawal from a normally behaving EOA
    function testLegitimateWithdrawWorks() public {
        uint depositValue = 1 ether;
        // Provide funds to this test contract
        vm.deal(address(this), 10 ether);

        // Deposit into FixedContract from this EOA
        fixedContract.deposit{value: depositValue}();
        // The mapping should reflect the deposit
        assertEq(fixedContract.balances(address(this)), depositValue);

        // Now perform a withdraw. Since this is an EOA, the transfer will succeed.
        fixedContract.withdraw();

        // After a successful withdrawal, the user balance should be reset to 0
        assertEq(fixedContract.balances(address(this)), 0);

        // And the test contract's balance should have increased by depositValue.
        // Initially we had 10 ether, after deposit our balance went to 9 ether, and after withdraw it should be back to 10 ether.
        assertEq(address(this).balance, 10 ether);

        // Finally, ensure that FixedContract holds no residual Ether
        assertEq(address(fixedContract).balance, 0);
    }

    // This receive function is needed so this contract can receive Ether upon withdrawal.
    receive() external payable {}
}
