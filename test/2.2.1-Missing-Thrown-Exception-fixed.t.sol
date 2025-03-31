pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Include the FixedToken and AttackFixedToken contracts

contract FixedToken {
    mapping(address => uint256) public balances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor(uint256 initialSupply) {
        balances[msg.sender] = initialSupply;
    }
    
    function transfer(address to, uint256 value) public returns(bool success) {
        require(balances[msg.sender] >= value && value > 0, "transfer failed: insufficient balance or invalid value");
        
        balances[msg.sender] = substractSafely(balances[msg.sender], value);
        balances[to] = addSafely(balances[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function substractSafely(uint256 a, uint256 b) internal pure returns(uint256) {
        return a - b;
    }
    
    function addSafely(uint256 a, uint256 b) internal pure returns(uint256) {
        return a + b;
    }
}

contract AttackFixedToken {
    FixedToken public token;

    // The attacking contract relies on FixedToken's address
    constructor(address tokenAddress) {
        token = FixedToken(tokenAddress);
    }

    function attackTransferWithInsufficientBalance() public returns (bool) {
        try token.transfer(address(this), 1000) returns (bool result) {
            return result;
        } catch {
            // The call reverts as expected due to insufficient balance
            return false;
        }
    }
}

contract FixedTokenTest is Test {
    FixedToken token;
    AttackFixedToken attack;
    
    address deployer = address(this); // test contract is the deployer
    address alice = address(0x1);
    address bob = address(0x2);

    // Event definition to match the one emitted by FixedToken
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        // Deploy token with an initial supply of 1000 tokens
        token = new FixedToken(1000);

        // Transfer some tokens from deployer to alice
        // Deployer has 1000 initially, send 500 to alice
        token.transfer(alice, 500);

        // Deploy the attack contract with the token address
        attack = new AttackFixedToken(address(token));
    }

    // Test 1: Successful transfer when there is enough balance
    function testSuccessfulTransfer() public {
        // Simulate the call from alice
        vm.prank(alice);

        // Since alice has 500 tokens, transferring 100 should succeed and emit an event
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, 100);

        bool result = token.transfer(bob, 100);
        assertTrue(result, "Transfer should succeed when balance is sufficient");
        
        // Validate balances
        uint256 aliceBalance = token.balances(alice);
        uint256 bobBalance = token.balances(bob);
        assertEq(aliceBalance, 400, "Alice should have 400 tokens after transfer");
        assertEq(bobBalance, 100, "Bob should have 100 tokens after receiving transfer");
    }

    // Test 2: Transfer reverts if caller has insufficient balance
    function testTransferFailsInsufficientBalance() public {
        // Bob has 0 tokens, so transferring 50 should revert due to insufficient balance
        vm.prank(bob);
        vm.expectRevert(bytes("transfer failed: insufficient balance or invalid value"));
        token.transfer(address(0x3), 50);
    }

    // Test 3: Transfer reverts if value is invalid (zero value transfer)
    function testTransferFailsInvalidValueZero() public {
        // Alice has tokens but transferring zero should revert
        vm.prank(alice);
        vm.expectRevert(bytes("transfer failed: insufficient balance or invalid value"));
        token.transfer(bob, 0);
    }

    // Test 4: Attack contract's attempt to transfer tokens with insufficient balance
    function testAttackTransferWithInsufficientBalance() public {
        // The attackTransferWithInsufficientBalance function should catch the revert and return false
        bool attackResult = attack.attackTransferWithInsufficientBalance();
        assertFalse(attackResult, "Attack should fail and return false when transfer reverts");
    }
}
