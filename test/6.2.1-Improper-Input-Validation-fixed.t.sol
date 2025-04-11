pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/6.2.1-Improper-Input-Validation-fixed.sol";

contract NonPayloadAttackableTokenFixedTest is Test {
    NonPayloadAttackableTokenFixed token;
    AttackFixed attacker;

    address owner = address(0x1);
    address user = address(0x2);

    function setUp() public {
        // Set up the token with owner as the deployer
        vm.prank(owner);
        token = new NonPayloadAttackableTokenFixed();

        // Deploy the attack contract with the token address
        attacker = new AttackFixed(address(token));
    }

    function testNormalTransfer() public {
        uint256 amount = 100;
        
        // Execute a proper transfer from owner to user
        vm.prank(owner);
        token.transfer(user, amount);
        
        // Check balances
        assertEq(token.balances(owner), 1000 - amount, "Owner balance should decrease by transferred amount");
        assertEq(token.balances(user), amount, "User balance should increase by transferred amount");
    }

    function testAttackWithShortPayload() public {
        uint256 amount = 50;
        
        // Create a correctly encoded payload for transfer
        bytes memory fullPayload = abi.encodeWithSelector(token.transfer.selector, user, amount);
        // Ensure payload has the expected length
        assertEq(fullPayload.length, 68, "Payload should be 68 bytes");
        
        // Construct a short (malicious) payload by removing some bytes from the end
        bytes memory shortPayload = new bytes(fullPayload.length - 10);
        for (uint i = 0; i < shortPayload.length; i++) {
            shortPayload[i] = fullPayload[i];
        }

        // The AttackFixed contract expects the call to fail due to payload size check.
        // Its attack() function will revert with a custom error message if the underlying call fails.
        vm.expectRevert("Attack failed as expected due to payload size check");
        attacker.attack(shortPayload);
    }

    function testDirectShortCallFails() public {
        uint256 amount = 70;
        
        // Create a correct payload
        bytes memory fullPayload = abi.encodeWithSelector(token.transfer.selector, user, amount);
        // Modify the payload to be short
        bytes memory shortPayload = new bytes(fullPayload.length - 5);
        for (uint i = 0; i < shortPayload.length; i++) {
            shortPayload[i] = fullPayload[i];
        }

        // Directly call the token with the short payload; expect revert with "Invalid payload size"
        vm.expectRevert("Invalid payload size");
        (bool success, ) = address(token).call(shortPayload);
        require(!success, "Direct call with short payload should have failed");
    }
}
