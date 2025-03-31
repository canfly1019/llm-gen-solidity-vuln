pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the contracts under test. Adjust the path if needed.
import "../src/5.16-Wrong-Logic-fixed.sol";

// A simple mock user contract to simulate an EOA interacting with WrongLogicFixed
contract MockUser {
    WrongLogicFixed fixedContract;
    
    constructor(address _fixedContract) {
        fixedContract = WrongLogicFixed(payable(_fixedContract));
    }

    // Calls claimReward on the fixed contract
    function claimReward() public {
        fixedContract.claimReward();
    }

    // Allow the contract to receive ether
    receive() external payable {}
}

contract WrongLogicFixedTest is Test {
    WrongLogicFixed fixedContract;
    AttackWrongLogicFixed attacker;
    
    function setUp() public {
        // Deploy the fixed contract with enough ether (2 ether, for example)
        fixedContract = new WrongLogicFixed{value: 2 ether}();
        
        // Deploy the attacker contract passing the address of the fixed contract
        attacker = new AttackWrongLogicFixed(payable(address(fixedContract)));
    }
    
    // Test that the attacker's first call to claimReward succeeds and transfers 1 ether
    function testAttackerSingleClaim() public {
        // Call attack() the first time
        attacker.attack();
        
        // Check that the attacker contract's balance increased by 1 ether reward
        uint attackerBalance = address(attacker).balance;
        assertEq(attackerBalance, 1 ether, "Attacker should have received 1 ether reward after first attack");
    }
    
    // Test that repeated claim attempts by the attacker are blocked
    function testAttackerRepeatedClaim() public {
        // Execute the first successful claim
        attacker.attack();
        
        // Expect the second call to revert with the message "Already claimed reward"
        vm.expectRevert(bytes("Already claimed reward"));
        attacker.attack();
    }
    
    // Test that an EOA (simulated by a MockUser contract) cannot claim reward twice
    function testRepeatedClaimByEOA() public {
        // Deploy a mock user which will interact with the fixed contract
        MockUser user = new MockUser(address(fixedContract));
        
        // First claim should succeed
        user.claimReward();
        
        // Second claim should revert with "Already claimed reward"
        vm.expectRevert(bytes("Already claimed reward"));
        user.claimReward();
    }
}
