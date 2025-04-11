pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/8.3.2-Improper-Check-against-Signature-Replay-Attacks-fixed.sol";

contract FixedTest is Test {
    Fixed public target;
    
    // We will use a known private key for the signer (not secure in prod, only for testing)
    uint256 internal constant SIGNER_PRIVATE_KEY = 0xBEEF;
    address public signerAddress;

    function setUp() public {
        signerAddress = vm.addr(SIGNER_PRIVATE_KEY);
        target = new Fixed(signerAddress);
    }

    // Helper function to generate a valid signature for a given message
    function signMessage(string memory _message, uint256 privateKey) internal view returns (bytes memory) {
        // The contract calculates:
        // innerHash = keccak256(abi.encodePacked(_message))
        // ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", innerHash))
        
        bytes32 innerHash = keccak256(abi.encodePacked(_message));
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", innerHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethHash);
        return abi.encodePacked(r, s, v);
    }

    // Helper function to alter signature's s value to an invalid one (greater than allowed)
    function corruptS(bytes memory signature) internal pure returns (bytes memory) {
        require(signature.length == 65, "Signature length must be 65");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        // Set s to an invalid value: just one greater than the maximum allowed
        // Maximum allowed value: 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0
        // We'll set it to max + 1
        s = bytes32(uint256(0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0) + 1);
        return abi.encodePacked(r, s, v);
    }

    // Helper function to alter signature's v value to an invalid one
    function corruptV(bytes memory signature) internal pure returns (bytes memory) {
        require(signature.length == 65, "Signature length must be 65");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        // Set v to an invalid value (e.g. 29)
        v = 29;
        return abi.encodePacked(r, s, v);
    }

    
    // Test that a valid message and signature processes correctly
    function testValidProcessMessage() public {
        string memory message = "Hello";
        bytes memory signature = signMessage(message, SIGNER_PRIVATE_KEY);

        // Expect no revert
        target.processMessage(message, signature);

        // Check processedHashes mapping. It is computed as keccak256(abi.encodePacked(address(this), message))
        // But note: the contract uses its own address (target) rather than msg.sender. So we replicate that:
        bytes32 msgHash = keccak256(abi.encodePacked(address(target), message));
        bool processed = target.processedHashes(msgHash);
        assertTrue(processed, "Message hash should be marked as processed");
    }

    // Test that replaying the same message fails
    function testReplayAttackPrevention() public {
        string memory message = "ReplayTest";
        bytes memory signature = signMessage(message, SIGNER_PRIVATE_KEY);

        // First call should succeed
        target.processMessage(message, signature);

        // Second call using same signature should revert because the message hash is already processed
        vm.expectRevert("Message already processed");
        target.processMessage(message, signature);
    }

    // Test that attempting to use a valid message with a signature altered for signature malleability (modified v) fails
    function testInvalidVValue() public {
        string memory message = "InvalidV";
        bytes memory signature = signMessage(message, SIGNER_PRIVATE_KEY);
        signature = corruptV(signature);

        vm.expectRevert("Invalid signature 'v' value");
        target.processMessage(message, signature);
    }

    // Test that attempting to use a signature with an invalid s value fails
    function testInvalidSValue() public {
        string memory message = "InvalidS";
        bytes memory signature = signMessage(message, SIGNER_PRIVATE_KEY);
        signature = corruptS(signature);

        vm.expectRevert("Invalid signature 's' value");
        target.processMessage(message, signature);
    }

    // Test that using a signature from an unauthorized signer fails
    function testUnauthorizedSigner() public {
        string memory message = "WrongSigner";
        // Use a different private key that is not the expected signer
        uint256 fakePrivateKey = 0xABCD;
        bytes memory signature = signMessage(message, fakePrivateKey);

        vm.expectRevert("Invalid signature");
        target.processMessage(message, signature);
    }
}
