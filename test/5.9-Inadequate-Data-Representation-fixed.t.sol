pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

import "forge-std/Test.sol";
import "../src/5.9-Inadequate-Data-Representation-fixed.sol";

contract InadequateDataRepresentationTest is Test {
    MyContract public myContract;
    address public user;
    address public attacker;

    function setUp() public {
        myContract = new MyContract();
        user = vm.addr(100);
        attacker = vm.addr(101);
        vm.deal(user, 10 ether);
        vm.deal(attacker, 10 ether);
    }

    function testCorrectDepositAndWithdraw() public {
        // Use a non-precompile EOA (user) to avoid fallback gas issues.
        vm.prank(user);
        myContract.deposit{value: 1 ether}();
        // After deposit, the contract should hold 1 ether.
        assertEq(address(myContract).balance, 1 ether, "Contract should hold 1 ether after deposit");

        vm.prank(user);
        myContract.withdraw();
        // After withdrawal, the contract's balance should be zero because 1 ether was transferred.
        assertEq(address(myContract).balance, 0, "Contract balance should be zero after withdrawal");
    }

    function testDepositRevertOnWrongAmount() public {
        vm.prank(user);
        vm.expectRevert(bytes("Deposit 1 ether exactly"));
        myContract.deposit{value: 0.5 ether}();
    }

    function testAttackDoesNotExtractExtraFunds() public {
        // Deploy the Attack contract using a non-precompile attacker address.
        vm.prank(attacker);
        Attack attackContract = new Attack(address(myContract));

        vm.prank(attacker);
        // The attack function expects exactly 1 ether to be sent
        attackContract.attack{value: 1 ether}();

        // The Attack contract should have received exactly 1 ether from the withdrawal
        assertEq(address(attackContract).balance, 1 ether, "Attack contract should only receive 1 ether");
        // The MyContract balance should be zero after the withdrawal
        assertEq(address(myContract).balance, 0, "MyContract balance should be zero after attack execution");
    }
}
