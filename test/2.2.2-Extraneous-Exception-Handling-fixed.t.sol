pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// FixedToken contract with extraneous exception handling removed
contract FixedToken {
    mapping(address => uint) public balances;
    
    // The deployer is given 1000 wei upon deployment
    constructor() {
        balances[msg.sender] = 1000;
    }
    
    // transferFrom now only checks that the caller has enough balance
    function transferFrom(address _spender, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        
        balances[msg.sender] -= _value;
        balances[_spender] += _value;
        return true;
    }
    
    // Utility: get balance.
    function getBalance(address account) public view returns (uint) {
        return balances[account];
    }
}

// FixedAttackContract that calls transferFrom with a value (e.g., 25 wei)
contract FixedAttackContract {
    FixedToken public fixedToken;
    
    // Set the FixedToken contract address during construction
    constructor(address _fixedTokenAddress) {
        fixedToken = FixedToken(_fixedTokenAddress);
    }
    
    // Attack function which attempts to transfer 25 wei tokens
    // Note: When this function is called, msg.sender is the caller of attack(),
    // but inside FixedToken.transferFrom, the msg.sender will be this contract.
    function attack() public {
        fixedToken.transferFrom(msg.sender, 25 wei);
    }
}

// Forge test contract
contract ExtraneousExceptionHandlingFixedTest is Test {
    FixedToken token;
    FixedAttackContract attackContract;

    address deployer = address(1);
    address attacker = address(2);

    function setUp() public {
        // Deploy FixedToken as deployer, initial balance 1000 allocated to deployer
        vm.startPrank(deployer);
        token = new FixedToken();
        vm.stopPrank();
        
        // Deploy FixedAttackContract as attacker (so that the attack contract is deployed by attacker)
        vm.prank(attacker);
        attackContract = new FixedAttackContract(address(token));
    }

    // Test that attack succeeds when the attack contract has enough balance to perform the transfer
    function testAttackWorks() public {
        // Fund the attack contract with 100 wei tokens
        // Use deployer (who owns the tokens) to send tokens to the attack contract
        vm.prank(deployer);
        // Here deployer calls transferFrom() so that msg.sender is deployer, and target is attackContract
        token.transferFrom(address(attackContract), 100);
        
        // Verify the funding: attack contract should now hold 100 tokens
        uint balanceAttackBefore = token.getBalance(address(attackContract));
        assertEq(balanceAttackBefore, 100, "Attack contract should be funded with 100 tokens");
        
        // Now, have attacker call attack() via the attack contract
        vm.prank(attacker);
        attackContract.attack();
        
        // After attack, the FixedAttackContract (i.e., msg.sender in transferFrom becomes attackContract)
        // should have 25 tokens deducted; and the attacker (provided as _spender) receives 25 tokens
        uint balanceAttackAfter = token.getBalance(address(attackContract));
        uint balanceAttacker = token.getBalance(attacker);
        
        assertEq(balanceAttackAfter, 75, "Attack contract should have 75 tokens after transferring 25 tokens");
        assertEq(balanceAttacker, 25, "Attacker should receive 25 tokens");
    }

    // Test that the attack reverts if the attack contract doesn't have enough tokens
    function testAttackFailsDueToInsufficientBalance() public {
        // Do NOT fund the attack contract so its balance remains 0
        vm.prank(attacker);
        vm.expectRevert(bytes("Insufficient balance"));
        attackContract.attack();
    }
}
