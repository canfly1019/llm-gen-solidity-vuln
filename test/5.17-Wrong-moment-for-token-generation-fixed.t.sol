pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Include the FixedTokenSale and AttackFixed contracts

contract FixedTokenSale {
    mapping(address => uint256) public balances;
    uint256 public tokenPrice = 1 ether;

    function buyTokens() public payable {
        require(msg.value >= tokenPrice, "Insufficient Ether");
        uint256 tokens = msg.value / tokenPrice;
        balances[msg.sender] += tokens;
    }
}

contract AttackFixed {
    FixedTokenSale public fixedSale;
    address public attacker;

    constructor(address _fixedSale) {
        fixedSale = FixedTokenSale(_fixedSale);
        attacker = msg.sender;
    }

    function attack() public payable {
        require(msg.sender == attacker, "Not authorized");
        fixedSale.buyTokens{value: msg.value}();
    }

    function getMyTokens() public view returns (uint256) {
        // Gets tokens from the fixedSale but note: tokens are minted to this contract's address
        return fixedSale.balances(address(this));
    }
}

contract FixedTokenSaleTest is Test {
    FixedTokenSale fixedSale;
    AttackFixed attackFixed;

    address attacker = address(0xABcD);

    function setUp() public {
        // Deploy FixedTokenSale
        fixedSale = new FixedTokenSale();
        
        // Set some ether to the attacker address
        vm.deal(attacker, 10 ether);
        
        // Prank as attacker for deploying AttackFixed so that attacker is recorded as the deployer
        vm.startPrank(attacker);
        attackFixed = new AttackFixed(address(fixedSale));
        vm.stopPrank();
    }

    // Test that buying tokens directly mints tokens to msg.sender (general check)
    function testBuyTokensMintsToSender() public {
        // At the beginning, caller does not have tokens
        uint256 preBalance = fixedSale.balances(address(this));
        assertEq(preBalance, 0);
        
        // Buy tokens from this contract directly
        fixedSale.buyTokens{value: 1 ether}();
        
        uint256 postBalance = fixedSale.balances(address(this));
        assertEq(postBalance, 1);
    }

    // Test that attack cannot mint tokens to an arbitrary address
    // Instead, tokens minted via AttackFixed go to the AttackFixed contract's address, not the attacker's externally controlled address
    function testAttackCannotMintToArbitraryAddress() public {
        // Prank as attacker so that msg.sender in AttackFixed.attack equals attacker
        vm.startPrank(attacker);
        // Attack with 2 ether - expecting to mint 2 tokens but to the AttackFixed contract, not to the attacker's EOA
        attackFixed.attack{value: 2 ether}();
        vm.stopPrank();
        
        // Check tokens minted by FixedTokenSale
        // They should be credited to the AttackFixed contract's address since buyTokens uses msg.sender
        uint256 tokensInAttackContract = fixedSale.balances(address(attackFixed));
        assertEq(tokensInAttackContract, 2);
        
        // The attacker's address should not receive any tokens even though he initiated the transaction
        uint256 tokensInAttacker = fixedSale.balances(attacker);
        assertEq(tokensInAttacker, 0);
    }

    // Test that buying tokens with insufficient Ether reverts
    function testBuyTokensFailsInsufficientEther() public {
        vm.expectRevert("Insufficient Ether");
        fixedSale.buyTokens{value: 0.5 ether}();
    }
}
