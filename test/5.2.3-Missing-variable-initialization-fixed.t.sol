pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "forge-std/Test.sol";

/*
    修正後程式碼：
    說明：在部署合約時的 constructor 中正確初始化 destination，避免預設值為 address(0) 的漏洞。
*/

contract Uninitialized {
    // 將 destination 宣告為 payable 並在 constructor 中初始化為部署者地址
    address payable public destination;

    constructor() {
        destination = payable(msg.sender);
    }

    // transfer() 函式：收到的 Ether 轉移至正確初始化後的 destination
    function transfer() public payable {
        destination.transfer(msg.value);
    }

    // 接收 Ether 的 fallback 函式
    receive() external payable {}
}

// 攻擊合約：此合約僅作為範例，呼叫 transfer() 後 Ether 會轉移到正確的 destination
contract Attack {
    Uninitialized public target;

    // 為解決編譯錯誤，將 _target 參數型態修改為 address payable
    constructor(address payable _target) {
        target = Uninitialized(_target);
    }

    function attack() external payable {
        target.transfer{value: msg.value}();
    }
}


// Forge test contract
contract MissingVariableInitializationFixedTest is Test {

    // Test to ensure the destination is properly initialized to the deployer's address
    function testDestinationInitialization() public {
        // use a non-precompile address for deployer
        address deployer = vm.addr(100);
        vm.deal(deployer, 10 ether);

        vm.startPrank(deployer);
            Uninitialized uninit = new Uninitialized();
        vm.stopPrank();

        // verify that destination is set to the deployer's address
        address payable dest = uninit.destination();
        assertEq(dest, deployer, "Destination should be the deployer address");
    }

    // Test that funds sent via transfer() are properly forwarded to the destination
    function testTransferFunds() public {
        // use a non-precompile address for deployer
        address deployer = vm.addr(101);
        vm.deal(deployer, 10 ether);

        vm.startPrank(deployer);
            Uninitialized uninit = new Uninitialized();
        vm.stopPrank();

        // Check that destination is the deployer
        assertEq(uninit.destination(), deployer, "Destination mismatch");

        // Set up an external account (attacker/sender) with funds
        address sender = vm.addr(102);
        vm.deal(sender, 10 ether);

        // Record deployer's balance before transfer
        uint256 initialBalance = deployer.balance;

        // Sender sends 1 ether to the Uninitialized contract via transfer()
        vm.prank(sender);
        uninit.transfer{value: 1 ether}();

        // Check that the deployer's balance has been increased by 1 ether
        uint256 finalBalance = deployer.balance;
        assertEq(finalBalance, initialBalance + 1 ether, "Deployer did not receive funds from transfer");
    }

    // Test that the Attack contract properly calls transfer() and funds are forwarded to the destination
    function testAttackTransferFunds() public {
        // use a non-precompile address for deployer
        address deployer = vm.addr(103);
        vm.deal(deployer, 10 ether);

        // Deploy the Uninitialized contract from deployer
        vm.startPrank(deployer);
            Uninitialized uninit = new Uninitialized();
        vm.stopPrank();

        // Verify destination is set to deployer
        assertEq(uninit.destination(), deployer, "Destination should be deployer address");

        // Deploy the Attack contract from another non-precompile address
        address attackerDeployer = vm.addr(104);
        vm.deal(attackerDeployer, 10 ether);
        vm.startPrank(attackerDeployer);
            Attack attackContract = new Attack(payable(address(uninit)));
        vm.stopPrank();

        // Use another account to perform the attack
        address attacker = vm.addr(105);
        vm.deal(attacker, 10 ether);

        // Record deployer's balance before attack transfer
        uint256 initialBalance = deployer.balance;

        // Call attack() from the attacker account with 1 ether
        vm.prank(attacker);
        attackContract.attack{value: 1 ether}();

        // Check that deployer's balance increased by 1 ether
        uint256 finalBalance = deployer.balance;
        assertEq(finalBalance, initialBalance + 1 ether, "Deployer did not receive funds from attack transfer");
    }
}
