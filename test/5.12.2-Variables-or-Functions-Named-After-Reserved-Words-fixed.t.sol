pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// We include the BugFixed and AttackFixed contracts as provided in the prompt.

contract BugFixed {
    // The variable name is agora instead of now to avoid conflict with the built-in function.
    uint public agora;

    constructor() {
        agora = block.timestamp;
    }

    // Renamed to avoid conflicts with Solidity's built-in assert.
    function assertAgora(bool condition) public pure {
        require(condition, "Assertion failed");
    }

    // Returns the expiration time based on the stored agora value.
    function get_next_expiration(uint earlier_time) public view returns (uint) {
        return agora + 259200;
    }
}

contract AttackFixed {
    BugFixed public fixedContract;

    constructor(address _fixedAddress) {
        fixedContract = BugFixed(_fixedAddress);
    }

    function attackFixed() public view returns (uint) {
        return fixedContract.get_next_expiration(block.timestamp);
    }
}

// Foundry test contract
contract BugFixedTest is Test {
    BugFixed bugFixed;
    AttackFixed attackFixed;

    // Set up the contracts before each test
    function setUp() public {
        bugFixed = new BugFixed();
        attackFixed = new AttackFixed(address(bugFixed));
    }

    // Test that BugFixed initializes the agora variable to the deployment time.
    function testInitialization() public {
        // Since the deployment sets agora equal to block.timestamp,
        // we cannot call block.timestamp directly after deployment since time might have advanced.
        // But since we deploy in setUp, we simulate and record current time using vm.now.
        uint deployedAgora = bugFixed.agora();
        // Ensure that the stored agora is not zero.
        assertGt(deployedAgora, 0);
    }

    // Test that get_next_expiration returns agora + 259200, regardless of the input.
    function testGetNextExpiration() public {
        uint initialAgora = bugFixed.agora();
        uint expectedExpiration = initialAgora + 259200;

        // Call with an arbitrary parameter (which is ignored in the implementation)
        uint expiration = bugFixed.get_next_expiration(block.timestamp);

        assertEq(expiration, expectedExpiration, "Expiration time should be fixed as agora + 259200");

        // Also, warp time to a future timestamp and verify that get_next_expiration still returns the same result
        vm.warp(block.timestamp + 1000);
        uint expirationAfterWarp = bugFixed.get_next_expiration(block.timestamp);
        assertEq(expirationAfterWarp, expectedExpiration, "Expiration time should remain constant after time warp");
    }

    // Test that assertAgora works as intended when condition is true
    function testAssertAgoraSucceeds() public {
        // This should not revert
        bugFixed.assertAgora(true);
    }

    // Test that assertAgora reverts when condition is false, checking the error message
    function testAssertAgoraFails() public {
        vm.expectRevert(bytes("Assertion failed"));
        bugFixed.assertAgora(false);
    }

    // Test the AttackFixed contract to ensure that the attack (which was supposed to demonstrate the vulnerability but is fixed) returns the correct value
    function testAttackFixed() public {
        uint initialAgora = bugFixed.agora();
        uint expectedExpiration = initialAgora + 259200;

        uint attackResult = attackFixed.attackFixed();
        assertEq(attackResult, expectedExpiration, "AttackFixed should return agora + 259200");
    }
}
