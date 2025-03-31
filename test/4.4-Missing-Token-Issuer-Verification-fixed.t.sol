pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Contract under test: FixedTicket with fixed token issuer verification
contract FixedTicket {
    address public tokenIssuer;
    address public sponsor;

    constructor(address _tokenIssuer, address _sponsor) {
        tokenIssuer = _tokenIssuer;
        sponsor = _sponsor;
    }

    // Only tokenIssuer is allowed to call transfer()
    function transfer() external payable {
        require(msg.sender == tokenIssuer, "Caller is not token issuer");
        runSponsor();
    }

    function otherAction() external payable {
        require(msg.sender == tokenIssuer || msg.sender == address(this), "Not allowed");
        // Additional logic could be placed here
    }

    // runSponsor transfers entire contract balance to msg.sender
    function runSponsor() internal {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}

contract FixedTicketTest is Test {
    FixedTicket public fixedTicket;

    // Declare test addresses
    address payable public tokenIssuer = payable(address(0xABCD));
    address payable public sponsor = payable(address(0xBEEF));
    address payable public attacker = payable(address(0xDEAD));

    // setUp deploys the contract under test
    function setUp() public {
        // Label addresses for better output
        vm.label(tokenIssuer, "TokenIssuer");
        vm.label(sponsor, "Sponsor");
        vm.label(attacker, "Attacker");

        fixedTicket = new FixedTicket(tokenIssuer, sponsor);

        // Fund tokenIssuer and attacker with ETH for testing
        vm.deal(tokenIssuer, 10 ether);
        vm.deal(attacker, 10 ether);

        // Fund the contract with some ETH so that transfer() can send funds
        (bool success, ) = address(fixedTicket).call{value: 1 ether}('');
        require(success, "Initial deposit failed");
    }

    // Test that the tokenIssuer is allowed to call transfer and withdraws the ETH
    function testTokenIssuerCanCallTransfer() public {
        // Record tokenIssuer balance before calling transfer
        uint256 balanceBefore = tokenIssuer.balance;
        
        // Execute transfer from tokenIssuer
        vm.prank(tokenIssuer);
        fixedTicket.transfer();
        
        // After transfer, the contract's balance should be empty
        assertEq(address(fixedTicket).balance, 0, "Contract balance should be zero after transfer");

        // Token issuer should have received 1 ether from the contract
        uint256 balanceAfter = tokenIssuer.balance;
        assertEq(balanceAfter, balanceBefore + 1 ether, "Token issuer did not receive the proper reward");
    }

    // Test that an attacker (non tokenIssuer) cannot call transfer
    function testAttackerCannotCallTransfer() public {
        // Expect the call to revert with the proper error message
        vm.prank(attacker);
        vm.expectRevert("Caller is not token issuer");
        fixedTicket.transfer();
    }
}
