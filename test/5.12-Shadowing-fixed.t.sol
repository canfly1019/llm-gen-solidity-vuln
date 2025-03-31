pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the Fixed and AttackFixed contracts from the provided file 5.12-Shadowing-fixed.sol
// Adjust the path as necessary if using a different file structure.

// For the purpose of the test, we re-define them here.

contract Fixed {
    // State variable that correctly stores the deposit amount
    uint public balance;

    // Renamed parameter to avoid shadowing with the state variable
    function deposit(uint amount) public payable {
        require(msg.value == amount, "Incorrect value");
        // Correctly update the state variable balance
        balance += msg.value;
    }

    function getBalance() public view returns(uint) {
        return balance;
    }
}

contract AttackFixed {
    Fixed public fixedContract;

    // Deploy with the address of the Fixed contract
    constructor(address _fixedContract) {
        fixedContract = Fixed(_fixedContract);
    }

    // The attack consists in simply depositing Ether into the Fixed contract.
    function attack() public payable {
        fixedContract.deposit{value: msg.value}(msg.value);
    }
}


contract FixedTest is Test {
    Fixed fixedContract;
    AttackFixed attackContract;

    // Setup function is called before each test.
    function setUp() public {
        fixedContract = new Fixed();
        // We deploy the AttackFixed contract with the address of the Fixed contract
        attackContract = new AttackFixed(address(fixedContract));
    }

    // Test that depositing with a matching msg.value and parameter updates the balance correctly
    function testDepositWithMatchingValue() public {
        uint depositAmount = 1 ether;
        // Call deposit with the correct value
        fixedContract.deposit{value: depositAmount}(depositAmount);
        // Check that the balance in the contract is updated correctly
        uint contractBalance = fixedContract.getBalance();
        assertEq(contractBalance, depositAmount, "Balance should equal the deposited amount");
    }

    // Test that deposit reverts if the provided parameter amount doesn't match msg.value
    function testDepositWithMismatchedValue() public {
        uint depositParameter = 1 ether;
        uint sentValue = 0.5 ether;
        // Expect revert with the error message "Incorrect value"
        vm.expectRevert(bytes("Incorrect value"));
        fixedContract.deposit{value: sentValue}(depositParameter);
    }

    // Test that the AttackFixed contract correctly calls deposit and updates the Fixed contract balance
    function testAttackAndBalanceUpdate() public {
        uint depositAmount = 1 ether;
        // Call the attack function which in turn calls deposit with the correct msg.value
        attackContract.attack{value: depositAmount}();
        // Confirm that the balance of the Fixed contract now reflects the deposited amount.
        uint contractBalance = fixedContract.getBalance();
        assertEq(contractBalance, depositAmount, "Fixed contract balance should be updated after the attack");
    }
}
