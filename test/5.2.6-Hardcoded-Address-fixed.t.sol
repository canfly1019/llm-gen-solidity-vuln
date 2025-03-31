pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The FixedContract and FixedAttacker contracts as provided

contract FixedContract {
    address payable public beneficiary;

    constructor(address payable _beneficiary) {
         require(_beneficiary != address(0), "Invalid address");
         beneficiary = _beneficiary;
    }

    function donate() external payable {
        require(msg.value > 0, "Must send some Ether");
        beneficiary.transfer(msg.value);
    }

    receive() external payable {}
}

contract FixedAttacker {
    FixedContract public fixedContract;

    constructor(address _fixedContract) {
        fixedContract = FixedContract(payable(_fixedContract));
    }

    function attack() external payable {
        fixedContract.donate{value: msg.value}();
    }

    receive() external payable {}
}


contract FixedContractTest is Test {
    FixedContract public fixedContract;
    address payable beneficiary = payable(address(0xBEEF));
    uint256 initialBeneficiaryBalance;

    function setUp() public {
        // Label the beneficiary address for clarity
        vm.label(beneficiary, "Beneficiary");
        
        // Deploy the FixedContract with the given beneficiary
        fixedContract = new FixedContract(beneficiary);

        // Record the initial balance of the beneficiary
        initialBeneficiaryBalance = beneficiary.balance;
    }

    // Test that the constructor rejects a zero address
    function testConstructorRejectsZeroAddress() public {
        vm.expectRevert(bytes("Invalid address"));
        // Attempting to deploy with a zero address for beneficiary should revert
        new FixedContract(payable(address(0)));
    }

    // Test that donating Ether correctly forwards funds to the beneficiary
    function testDonationForwardsToBeneficiary() public {
        uint256 donationAmount = 1 ether;

        // Fund this test contract so it can send Ether
        vm.deal(address(this), 10 ether);
        
        // Check initial balance of beneficiary
        uint256 beneficiaryBalanceBefore = beneficiary.balance;

        // Donate to the FixedContract
        fixedContract.donate{value: donationAmount}();
        
        // Assert that the beneficiary received the donation
        uint256 beneficiaryBalanceAfter = beneficiary.balance;
        assertEq(beneficiaryBalanceAfter - beneficiaryBalanceBefore, donationAmount);
    }

    // Test that donating without sending Ether reverts with the proper message
    function testDonationFailsForNoEtherValue() public {
        vm.expectRevert(bytes("Must send some Ether"));
        fixedContract.donate{value: 0}();
    }

    // Test that even if an attacker contract attempts to redirect funds through its attack function,
    // the funds still end up with the originally designated beneficiary
    function testFixedAttackerDoesNotRedirectFunds() public {
        // Deploy attacker contract with the address of the fixedContract
        FixedAttacker attacker = new FixedAttacker(address(fixedContract));
        
        uint256 donationAmount = 0.5 ether;
        
        // Fund the attacker contract's caller so it can send Ether
        vm.deal(address(this), 10 ether);
        
        // Check beneficiary balance before attack
        uint256 beneficiaryBalanceBefore = beneficiary.balance;
        
        // The attacker contract calls attack which in turns calls donate on fixedContract.
        // We call it from this test contract.
        attacker.attack{value: donationAmount}();

        // Check beneficiary balance after attack; it should have increased by donationAmount
        uint256 beneficiaryBalanceAfter = beneficiary.balance;
        assertEq(beneficiaryBalanceAfter - beneficiaryBalanceBefore, donationAmount);
    }
}
