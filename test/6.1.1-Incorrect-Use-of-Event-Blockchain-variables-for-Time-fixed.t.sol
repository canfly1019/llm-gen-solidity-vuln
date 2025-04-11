pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/6.1.1-Incorrect-Use-of-Event-Blockchain-variables-for-Time-fixed.sol";

contract TestFixedTest is Test {
    TestFixed public testFixed;
    AttackFixed public attackFixed;

    // Funding amount for TestFixed so it can cover transfers
    uint256 constant INITIAL_FUNDS = 200;

    function setUp() public {
        testFixed = new TestFixed();
        attackFixed = new AttackFixed(address(testFixed));
        // Fund the TestFixed contract so that it can send 100 wei when needed
        vm.deal(address(testFixed), INITIAL_FUNDS);
    }

    function testFixedInitialBalance() public {
        // Verify that TestFixed contract has been funded with INITIAL_FUNDS
        assertEq(address(testFixed).balance, INITIAL_FUNDS);
    }

    function testPayEvenTimestampDirect() public {
        // Set block.timestamp to an even number so that pay() does NOT trigger the 100 wei transfer
        vm.warp(4000); // even

        address user = address(0x2);
        vm.deal(user, 1000);

        // Record initial balances
        uint256 initialUserBalance = user.balance;
        uint256 initialTestFixedBalance = address(testFixed).balance;

        // When user calls pay() with a trivial amount, the contract will simply accept the ether
        vm.prank(user);
        testFixed.pay{value: 1}();

        // The user's balance will drop by 1 wei and TestFixed's balance increases by 1 wei
        uint256 finalUserBalance = user.balance;
        uint256 finalTestFixedBalance = address(testFixed).balance;

        assertEq(initialUserBalance - finalUserBalance, 1, "User should only pay 1 wei");
        assertEq(finalTestFixedBalance, initialTestFixedBalance + 1, "TestFixed receives the 1 wei");
    }

    function testPayOddTimestampDirect() public {
        // Set block.timestamp to an odd number so that pay() does trigger the 100 wei transfer
        vm.warp(4001); // odd

        address user = address(0x3);
        vm.deal(user, 1000);

        // Record initial balances
        uint256 initialTestFixedBalance = address(testFixed).balance; // should be INITIAL_FUNDS

        // When user calls pay() with 1 wei, the contract will add 1 wei and then send out 100 wei
        // Thus, TestFixed's balance should reduce by 100 wei in total
        vm.prank(user);
        testFixed.pay{value: 1}();

        // Expected: TestFixed's new balance = INITIAL_FUNDS + 1 - 100
        uint256 expectedTestFixedBalance = initialTestFixedBalance + 1 - 100;
        assertEq(address(testFixed).balance, expectedTestFixedBalance, "TestFixed balance after payout");
    }

    function testAttackFixedEvenTimestamp() public {
        // Set timestamp to even so that no transfer occurs in pay()
        vm.warp(3000); // even

        address attacker = address(0x1);
        vm.deal(attacker, 1e18);

        // Record initial balances
        uint256 initialAttackBalance = address(attackFixed).balance; // should be 0
        uint256 initialTestFixedBalance = address(testFixed).balance;

        // AttackFixed.attack will call testFixed.pay; since timestamp is even, no transfer of 100 wei should occur
        vm.prank(attacker);
        attackFixed.attack{value: 1}();

        // AttackFixed contract should not have received any funds
        assertEq(address(attackFixed).balance, initialAttackBalance, "No funds should be transferred to AttackFixed on even timestamp");

        // TestFixed balance increases by the sent amount 1 wei
        assertEq(address(testFixed).balance, initialTestFixedBalance + 1, "TestFixed should receive the 1 wei from AttackFixed attack");
    }

    function testAttackFixedOddTimestamp() public {
        // Set timestamp to odd so that TestFixed.pay transfers 100 wei to msg.sender (i.e. AttackFixed)
        vm.warp(3001); // odd

        address attacker = address(0x1);
        vm.deal(attacker, 1e18);

        // Record initial balances
        uint256 initialAttackBalance = address(attackFixed).balance; // should be 0
        uint256 initialTestFixedBalance = address(testFixed).balance;

        // When AttackFixed.attack is called, it forwards 1 wei to testFixed.pay which triggers a 100 wei transfer to AttackFixed
        vm.prank(attacker);
        attackFixed.attack{value: 1}();

        // AttackFixed should now have received 100 wei
        assertEq(address(attackFixed).balance, initialAttackBalance + 100, "AttackFixed should win 100 wei on odd timestamp");

        // TestFixed's balance: increases by 1 wei from the call, then decreases by 100 wei payout
        uint256 expectedTestFixedBalance = initialTestFixedBalance + 1 - 100;
        assertEq(address(testFixed).balance, expectedTestFixedBalance, "TestFixed balance should reflect the payout");
    }
}
