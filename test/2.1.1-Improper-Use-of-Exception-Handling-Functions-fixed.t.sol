// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/2.1.1-Improper-Use-of-Exception-Handling-Functions-fixed.sol";

contract ImproperExceptionHandlingFixedTest is Test {
    Fixed public fixedContract;
    AttackerFixed public attacker;

    function setUp() public {
        // Deploy Fixed contract and AttackerFixed pointing to it
        fixedContract = new Fixed();
        attacker = new AttackerFixed(payable(address(fixedContract)));
        // Fund this test contract so it can send ETH to attacker.attack
        vm.deal(address(this), 5 ether);
    }

    // 1) A normal user should be able to deposit and then withdraw without issues
    function testDepositAndWithdraw_Succeeds() public {
        address user = address(0xCAFE);
        vm.deal(user, 5 ether);

        // Deposit 3 ETH
        vm.prank(user);
        fixedContract.deposit{value: 3 ether}();
        assertEq(fixedContract.balances(user), 3 ether);
        assertEq(address(fixedContract).balance, 3 ether);

        // Withdraw 2 ETH
        vm.prank(user);
        fixedContract.withdraw(2 ether);
        // User's internal balance should be reduced by 2 ETH
        assertEq(fixedContract.balances(user), 1 ether);
        // Contract should hold the remaining 1 ETH
        assertEq(address(fixedContract).balance, 1 ether);
    }

    // 2) Using the provided AttackerFixed (which has a receive() so fallback never reverts),
    //    the attack actually succeeds: deposit then withdraw sends ETH back to the attacker.
    function testAttackerFixed_DrainsFunds() public {
        // Before attack, attacker contract has zero balance
        assertEq(address(attacker).balance, 0);

        // Perform the attack: send exactly 1 ETH to attacker.attack
        attacker.attack{value: 1 ether}();

        // After attack:
        // - The Fixed contract's internal balance for attacker should be zero
        // - The Fixed contract's ETH balance should be zero (drained)
        // - The attacker contract should have received the 1 ETH back
        assertEq(fixedContract.balances(address(attacker)), 0);
        assertEq(address(fixedContract).balance, 0);
        assertEq(address(attacker).balance, 1 ether);
    }
}
