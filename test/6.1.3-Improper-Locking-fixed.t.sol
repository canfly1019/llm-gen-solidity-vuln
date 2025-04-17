// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/6.1.3-Improper-Locking-fixed.sol";

contract LockContractTest is Test {
    LockContract lockContract;
    ForceSender forceSender;

    // Mirror of the Locked event for decoding
    event Locked(address indexed owner, uint256 amount, Lock lockAddr, bytes edgewareAddr, bool isValidator, uint256 timestamp);

    function setUp() public {
        // deploy the fixed LockContract and the ForceSender attacker
        lockContract = new LockContract();
        forceSender = new ForceSender();
    }

    function testLockCreatesLockAndEmitsEvent() public {
        bytes memory edgeware = hex"1234";
        bool isValidator = true;
        uint256 term = 300;
        uint256 amount = 1 ether;

        // Record logs so we can inspect the Locked event
        vm.recordLogs();
        lockContract.lock{value: amount}(term, edgeware, isValidator);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // We expect exactly one event
        assertEq(entries.length, 1);

        // Decode the event data
        // topics: [eventSig, owner]
        // data: abi.encode(amount, lockAddr, edgewareAddr, isValidator, timestamp)
        (, bytes memory data) = (entries[0].topics, entries[0].data);
        (uint256 loggedAmount, Lock lockAddr, bytes memory loggedEdgeware, bool loggedIsValidator, uint256 timestamp) = abi.decode(
            data,
            (uint256, Lock, bytes, bool, uint256)
        );

        // Verify the event parameters
        assertEq(loggedAmount, amount);
        assertEq(loggedEdgeware, edgeware);
        assertEq(loggedIsValidator, isValidator);
        // The timestamp should be close to block.timestamp
        assertLt(block.timestamp - timestamp, 5);

        // The newly deployed Lock should hold exactly the amount sent
        assertEq(address(lockAddr).balance, amount);
    }

    function testForceSendExtraEthDoesNotRevertLock() public {
        bytes memory edgeware = hex"deadbeef";
        bool isValidator = false;
        uint256 term = 600;
        uint256 amount = 1 ether;

        // First lock to get a Lock instance
        vm.recordLogs();
        lockContract.lock{value: amount}(term, edgeware, isValidator);
        Vm.Log[] memory firstLogs = vm.getRecordedLogs();
        (, bytes memory firstData) = (firstLogs[0].topics, firstLogs[0].data);
        (, Lock targetLock, , , ) = abi.decode(firstData, (uint256, Lock, bytes, bool, uint256));

        // Forcefully send another 1 ETH into the Lock via selfdestruct
        forceSender.attack{value: amount}(payable(address(targetLock)));
        // Now the balance should have doubled
        assertEq(address(targetLock).balance, 2 ether);

        // Now call lock again, sending 2 ETH (equal to the forced balance)
        uint256 newAmount = 2 ether;
        // If the assert were strict equality, this would revert. Fixed code uses >= so it succeeds.
        vm.recordLogs();
        lockContract.lock{value: newAmount}(term, edgeware, isValidator);
        Vm.Log[] memory secondLogs = vm.getRecordedLogs();

        // Success means one more event was emitted
        assertEq(secondLogs.length, 1);
        (, bytes memory secondData) = (secondLogs[0].topics, secondLogs[0].data);
        (uint256 loggedAmount2, , , bool loggedIsValidator2, ) = abi.decode(
            secondData,
            (uint256, Lock, bytes, bool, uint256)
        );
        assertEq(loggedAmount2, newAmount);
        assertEq(loggedIsValidator2, isValidator);
    }
}