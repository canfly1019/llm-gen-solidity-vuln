// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/8.3.3-Improper-authenticity-check-fixed.sol";

contract FixedAuthTest is Test {
    FixedAuth fixedAuth;
    address authorizedSigner;
    uint256 authorizedPrivateKey = 1; // Using private key 1 for the authorized signer
    address caller = address(0xBEEF);

    // Event to mirror the one in FixedAuth
    event Executed(address caller, uint256 amount);

    function setUp() public {
        // Derive authorized signer address from its private key
        authorizedSigner = vm.addr(authorizedPrivateKey);
        // Deploy the FixedAuth contract with the correct authorizedSigner
        fixedAuth = new FixedAuth(authorizedSigner);
        
        // Fund the contract with Ether to cover transfers
        vm.deal(address(fixedAuth), 10 ether);
        // Ensure the caller has some balance too
        vm.deal(caller, 1 ether);
    }

    function testValidSignature() public {
        uint256 amount = 0.1 ether;
        // Prepare the message hash used in the contract. Note that the contract signs (msg.sender, amount)
        // Since we will call from 'caller', we sign (caller, amount).
        bytes32 messageHash = keccak256(abi.encodePacked(caller, amount));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        // Sign the message hash using the authorizedSigner's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(authorizedPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Expect the Executed event to be emitted
        vm.expectEmit(true, false, false, true);
        emit Executed(caller, amount);

        // Call execute() acting as 'caller'
        vm.prank(caller);
        fixedAuth.execute(amount, signature);

        // Verify that the caller received the correct Ether amount
        assertEq(caller.balance, 1 ether + amount);
        // Verify the contract lost the corresponding Ether
        assertEq(address(fixedAuth).balance, 10 ether - amount);
    }

    function testInvalidSignature() public {
        uint256 amount = 0.1 ether;
        // Generate a signature using a wrong private key (e.g., 2 instead of authorizedPrivateKey)
        uint256 wrongPrivKey = 2;
        bytes32 messageHash = keccak256(abi.encodePacked(caller, amount));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPrivKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Execute using 'caller' and expect a revert due to signature verification failure
        vm.prank(caller);
        vm.expectRevert("Signature verification failed");
        fixedAuth.execute(amount, signature);
    }

    function testIncorrectSignatureLength() public {
        uint256 amount = 0.1 ether;
        // Provide a signature with an incorrect length (64 bytes instead of 65)
        bytes memory invalidSignature = new bytes(64);
        
        vm.prank(caller);
        vm.expectRevert("Invalid signature length");
        fixedAuth.execute(amount, invalidSignature);
    }

    function testSignatureBoundToCaller() public {
        uint256 amount = 0.1 ether;
        // Sign message for a specific caller (our original 'caller')
        bytes32 messageHash = keccak256(abi.encodePacked(caller, amount));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(authorizedPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Now simulate a different caller trying to use the signature.
        address differentCaller = address(0xBEEF + 1);
        vm.prank(differentCaller);
        vm.expectRevert("Signature verification failed");
        fixedAuth.execute(amount, signature);
    }
}
