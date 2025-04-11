pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.6.5-Wrong-Type-in-Variable-Declaration-fixed.sol";

contract FixedSampleBytesArrayTest is Test {
    FixedSampleBytesArray fixedContract;
    AttackFixed attackContract;

    function setUp() public {
        fixedContract = new FixedSampleBytesArray();
    }

    // Test that a single append correctly appends data and stores in contiguous bytes
    function testSingleAppend() public {
        bytes memory data = hex"deadbeef"; // 4 bytes
        fixedContract.appendSimBytes(data);
        // Retrieve the stored simBytes and verify
        bytes memory result = fixedContract.simBytes();
        assertEq(result, data, "The simBytes storage should contain the appended data.");
    }

    // Test multiple appends in proper order
    function testMultipleAppends() public {
        bytes memory data1 = hex"01";
        bytes memory data2 = hex"02";
        bytes memory data3 = hex"03";

        fixedContract.appendSimBytes(data1);
        fixedContract.appendSimBytes(data2);
        fixedContract.appendSimBytes(data3);

        bytes memory expected = abi.encodePacked(data1, data2, data3);
        bytes memory actual = fixedContract.simBytes();
        assertEq(actual, expected, "The simBytes storage should correctly accumulate appended data in order.");
    }

    // Test AttackFixed contract calling multiple appendSimBytes
    function testAttackContract() public {
        // deploy the attack contract with the address of fixedContract
        attackContract = new AttackFixed(address(fixedContract));
        
        uint256 appendCount = 10;
        // call attack, which appends hex"00" repeatedly
        attackContract.attack(appendCount);

        // Expected simBytes should now be 10 repetitions of 0x00
        bytes memory expected = new bytes(appendCount);
        for (uint256 i = 0; i < appendCount; i++) {
            expected[i] = 0x00;
        }

        bytes memory actual = fixedContract.simBytes();
        assertEq(actual, expected, "After attack, simBytes should contain the correct number of appended 0x00 bytes.");
    }

    // Optional test: simulate many appends and measure gas usage indirectly
    // This test doesn't assert lower gas per se, but warns if gas consumption is excessive for large appends
    function testGasUsageUnderLoad() public {
        uint256 initialGas = gasleft();

        uint256 numAppends = 100;
        bytes memory singleByte = hex"ab";
        for (uint256 i = 0; i < numAppends; i++) {
            fixedContract.appendSimBytes(singleByte);
        }

        uint256 finalGas = gasleft();
        // Just a sanity check to guarantee execution and that gas isn't consumed in an unexpected manner
        // Note: This is not a strict measurement of gas efficiency but ensures the function completes under load.
        assertGt(initialGas, finalGas, "Gas should be consumed after multiple appends.");

        // Confirm the stored data length equals numAppends
        bytes memory stored = fixedContract.simBytes();
        assertEq(stored.length, numAppends, "Stored simBytes length should match the number of appends.");
    }
}
