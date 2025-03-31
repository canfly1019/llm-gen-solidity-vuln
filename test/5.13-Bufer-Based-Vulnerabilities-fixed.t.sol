pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the contracts to test
// The contracts under test:

contract FixedContract {
    bytes32[1] public buffer;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function writeData(bytes32[] calldata _data) external {
        require(_data.length <= buffer.length, "Input length too long");
        for (uint256 i = 0; i < _data.length; i++) {
            buffer[i] = _data[i];
        }
    }
}

contract AttackFixed {
    FixedContract public fixedContract;

    constructor(address _fixedContractAddress) {
        fixedContract = FixedContract(_fixedContractAddress);
    }

    function attack() public {
        bytes32[] memory maliciousData = new bytes32[](2);
        maliciousData[0] = bytes32(uint256(0));
        maliciousData[1] = bytes32(uint256(uint160(msg.sender)));

        fixedContract.writeData(maliciousData);
    }
}

// The Foundry test contract
contract FixedContractTest is Test {
    FixedContract fixedContract;
    address deployer = address(0xABCD);
    address attacker = address(0xBEEF);

    function setUp() public {
        vm.startPrank(deployer);
        fixedContract = new FixedContract();
        vm.stopPrank();
    }

    // Test that writing valid data (with length 1) succeeds and writes correctly.
    function testValidWrite() public {
        bytes32 testData = bytes32(uint256(123));
        bytes32[] memory data = new bytes32[](1);
        data[0] = testData;

        // Call as any account; use deployer for simplicity
        vm.prank(deployer);
        fixedContract.writeData(data);

        // Check that the buffer was updated with exact data
        bytes32 stored = fixedContract.buffer(0);
        assertEq(stored, testData, "Buffer data not stored correctly");
        
        // Also ensure that the owner remains unchanged
        address contractOwner = fixedContract.owner();
        assertEq(contractOwner, deployer, "Owner was modified inadvertently");
    }

    // Test that an attempt to write an oversized array (length 2) reverts, preventing overflow
    function testOverflowAttackFails() public {
        bytes32[] memory maliciousData = new bytes32[](2);
        maliciousData[0] = bytes32(uint256(0));
        maliciousData[1] = bytes32(uint256(uint160(attacker)));

        // Expect the transaction to revert with the given error message
        vm.expectRevert(bytes("Input length too long"));
        // Attempt attack, calling from the attacker address.
        vm.prank(attacker);
        fixedContract.writeData(maliciousData);
    }

    // For extra clarity, also test using the AttackFixed contract that the attack fails
    function testAttackContractFails() public {
        vm.prank(deployer);
        AttackFixed attackContract = new AttackFixed(address(fixedContract));

        // Expect the call to revert when attack is made
        vm.expectRevert(bytes("Input length too long"));
        vm.prank(attacker);
        attackContract.attack();
    }
}
