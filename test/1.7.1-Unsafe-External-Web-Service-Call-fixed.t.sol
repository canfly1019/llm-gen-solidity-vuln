pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/1.7.1-Unsafe-External-Web-Service-Call-fixed.sol";

contract FixedContractTest is Test {
    FixedContract target;

    // We'll use a known private key for the trusted signer in our tests
    uint256 trustedSignerKey = 1;
    address trustedSigner;

    function setUp() public {
        trustedSigner = vm.addr(trustedSignerKey);
        target = new FixedContract(trustedSigner);
    }

    // Helper function: signs the message (value, caller) using the provided key
    // The message is hashed as in the contract and prefixed with Ethereum's signed message prefix.
    function signMessage(uint _value, address _caller, uint256 _key) internal returns (bytes memory) {
        bytes32 messageHash = keccak256(abi.encodePacked(_value, _caller));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, ethSignedMessageHash);
        return abi.encodePacked(r, s, v);
    }

    // Test that updateValue works correctly with a valid signature
    function testUpdateValueWithValidSignature() public {
        uint newVal = 42;
        bytes memory signature = signMessage(newVal, address(this), trustedSignerKey);
        target.updateValue(newVal, signature);
        assertEq(target.value(), newVal);
    }

    // Test that updateValue reverts when provided with an invalid signature (signed by a non-trusted key)
    function testUpdateValueWithInvalidSignature() public {
        uint newVal = 99;
        // Use a wrong signing key
        uint256 invalidKey = 2;
        bytes memory signature = signMessage(newVal, address(this), invalidKey);
        vm.expectRevert("Invalid signature");
        target.updateValue(newVal, signature);
    }

    // Test that a signature generated for a different caller address does not work
    function testUpdateValueWithSignatureForDifferentCaller() public {
        uint newVal = 77;
        // Instead of signing for msg.sender (address(this)), sign for a different address
        address differentCaller = address(0x123);
        bytes memory signature = signMessage(newVal, differentCaller, trustedSignerKey);
        vm.expectRevert("Invalid signature");
        target.updateValue(newVal, signature);
    }
}
