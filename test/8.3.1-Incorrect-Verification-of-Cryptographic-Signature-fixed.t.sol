pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/8.3.1-Incorrect-Verification-of-Cryptographic-Signature-fixed.sol";

contract FixedTest is Test {
    Fixed public target;
    AttackFixed public attackContract;

    address public authorizedSigner;
    uint256 public authorizedSignerPrivateKey;

    // setUp: initialize authorized signer and deploy contracts
    function setUp() public {
        // Use a fixed private key for the authorized signer
        authorizedSignerPrivateKey = 0xBEEF;
        authorizedSigner = vm.addr(authorizedSignerPrivateKey);
        target = new Fixed(authorizedSigner);
        attackContract = new AttackFixed(address(target));
    }

    // Helper function to sign a message using the given signer's private key
    function signMessage(string memory message, uint256 signerKey) internal returns (bytes memory) {
        // Generate the message hash as is done in the Fixed contract
        bytes32 messageHash = keccak256(abi.encodePacked(message));
        // Apply the Ethereum Signed Message prefix
        bytes32 ethSignedMessageHash = ECDSALib.toEthSignedMessageHash(messageHash);

        // Sign the ethSignedMessageHash using the cheat code vm.sign; it returns (v, r, s)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, ethSignedMessageHash);
        return abi.encodePacked(r, s, v);
    }

    // Test that a valid signature from the authorized signer processes correctly
    function testValidSignature() public {
        string memory message = "Hello, world!";
        bytes memory signature = signMessage(message, authorizedSignerPrivateKey);
        
        // Should complete without reverting
        target.processMessage(message, signature);

        // Compute expected lastProcessedHash
        bytes32 messageHash = keccak256(abi.encodePacked(message));
        // initially lastProcessedHash is 0
        bytes32 expectedLastHash = keccak256(abi.encodePacked(bytes32(0), messageHash));
        assertEq(target.lastProcessedHash(), expectedLastHash);
    }

    // Test that an invalid signature (signed by someone else) fails
    function testInvalidSignature() public {
        string memory message = "Hello, world!";
        // Use a different key (not the authorized signer) to sign the message
        uint256 otherKey = authorizedSignerPrivateKey + 1;
        bytes memory signature = signMessage(message, otherKey);

        vm.expectRevert("Not authorized");
        target.processMessage(message, signature);
    }

    // Test replay attack: using a signature valid for one message on a different message
    function testReplayAttackAttempt() public {
        // Sign a message "Message A" with the authorized signer
        string memory messageA = "Message A";
        bytes memory signatureA = signMessage(messageA, authorizedSignerPrivateKey);

        // Attempt to process a different message "Message B" using the signature from message A
        vm.expectRevert("Not authorized");
        target.processMessage("Message B", signatureA);
    }

    // Test that using the AttackFixed contract to replay a valid signature with a different message fails
    function testAttackContractFails() public {
        // Sign a legit message using the authorized signer
        string memory legitMessage = "Legit Message";
        bytes memory legitSignature = signMessage(legitMessage, authorizedSignerPrivateKey);

        // The attacker attempts to use the legitimate signature for a fake message
        vm.expectRevert("Not authorized");
        attackContract.attack("Fake Message", legitSignature);
    }

    // Test that a signature with an invalid length reverts with the correct error message
    function testInvalidSignatureLength() public {
        string memory message = "Test";
        // Create a signature with invalid length (e.g., 64 bytes instead of 65 bytes)
        bytes memory invalidSignature = new bytes(64);

        vm.expectRevert("ECDSA: invalid signature length");
        target.processMessage(message, invalidSignature);
    }
}
