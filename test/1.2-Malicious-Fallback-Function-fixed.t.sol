pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Assuming the contracts are already compiled as provided in 1.2-Malicious-Fallback-Function-fixed.sol

interface IRegisterUser {
    function setNewUser(string calldata name) external returns (bool);
}

// We declare them here to let the tests compile, in case they are not imported.

contract RegisterUser {
    // Explicitly defined function for setting a new user
    function setNewUser(string calldata name) external returns (bool) {
        // Business logic omitted for brevity
        return true;
    }

    // Fallback function: reverts on any call that does not match an existing function
    fallback() external payable {
        revert("Function does not exist");
    }

    // receive function to accept Ether without modifying state
    receive() external payable {}
}

contract callExternalExample {
    function callRegisterUser(RegisterUser a, string calldata name) public returns (bool) {
        bool success = a.setNewUser(name);
        return success;
    }
}

contract Attacker {
    // Attacker attempts to use a non-existent function call
    function attack(RegisterUser target) public payable {
        (bool success, ) = address(target).call{value: msg.value}(abi.encodeWithSignature("nonExistentFunction()"));
        require(success, "Attack failed");
    }
}


contract RegisterUserTest is Test {
    RegisterUser registerUser;
    Attacker attacker;

    function setUp() public {
        registerUser = new RegisterUser();
        attacker = new Attacker();
    }

    function testSetNewUserWorks() public {
        // Calling the correct function should return true
        bool result = registerUser.setNewUser("Alice");
        assertTrue(result, "setNewUser should return true");
    }

    function testFallbackRevertsOnUnknownFunction() public {
        // Direct call with non existent function signature should fail and revert with correct message
        (bool success, bytes memory data) = address(registerUser).call(
            abi.encodeWithSignature("nonExistentFunction()")
        );
        assertFalse(success, "Call to non-existent function should fail");

        // Decode revert message: standard error message encoding: Function selector for Error(string) is 0x08c379a0
        // Skip the first 4 bytes (function selector) and then ABI-decode the string
        if(data.length >= 4) {
            // Remove the function selector
            bytes memory revertData = slice(data, 4, data.length - 4);
            string memory revertMessage = abi.decode(revertData, (string));
            assertEq(revertMessage, "Function does not exist", "Fallback should revert with 'Function does not exist'");
        }
    }

    function testReceiveAcceptsEther() public {
        // Test that sending Ether with empty calldata (triggering receive) does not revert
        uint initialBalance = address(registerUser).balance;
        (bool success, ) = address(registerUser).call{value: 1 ether}("");
        assertTrue(success, "Direct Ether transfer should succeed");
        assertEq(address(registerUser).balance, initialBalance + 1 ether, "Ether balance should be updated");
    }

    function testAttackRevertsViaFallback() public {
        // Attempting to attack using Attacker contract should revert
        // Expect the attack to revert with "Attack failed", because the fallback always reverts
        vm.expectRevert(bytes("Attack failed"));
        attacker.attack{value: 0.1 ether}(registerUser);
    }

    // Helper function to slice bytes array
    function slice(
        bytes memory data,
        uint start,
        uint len
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            switch iszero(len)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The length of the slice is len
                mstore(tempBytes, len)

                // Copy data from data pointer to the new memory pointer
                let src := add(add(data, 0x20), start)
                let dest := add(tempBytes, 0x20)
                for { let i := 0 } lt(i, len) { i := add(i, 32) } {
                    mstore(dest, mload(src))
                    dest := add(dest, 32)
                    src := add(src, 32)
                }

                // Update the free memory pointer by rounding up to the nearest 32 bytes
                mstore(0x40, and(add(dest, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                // Zero length slice
                mstore(tempBytes, 0)
                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    // Fallback to receive Ether if necessary
    receive() external payable {}
}