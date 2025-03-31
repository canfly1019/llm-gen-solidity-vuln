pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/1.7.4-Unsafe-External-File-Access-fixed.sol";

// The test focuses on the onlyOwner restricted update of fileData
// and confirms that processData returns consistent results based on fileData.

contract SafeFileAccessorTest is Test {
    SafeFileAccessor safeFile;
    address owner;
    address nonOwner;

    // re-declare the event so we can use expectEmit
    event FileDataUpdated(string newData);

    function setUp() public {
        // The test contract is the deployer and will be owner
        owner = address(this);
        safeFile = new SafeFileAccessor("initial");
        nonOwner = address(0x1337);
    }

    // Test that the owner can update fileData and the event is emitted correctly
    function testOwnerCanUpdateFileData() public {
        string memory newData = "approved";
        // Expect the FileDataUpdated event to be emitted
        vm.expectEmit(true, true, true, true);
        emit FileDataUpdated(newData);
        safeFile.updateFileData(newData);

        // Verify that fileData has been updated
        assertEq(safeFile.fileData(), newData, "fileData should be updated to new value");
    }

    // Test that a non-owner cannot update the fileData
    function testNonOwnerCannotUpdateFileData() public {
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Not owner"));
        safeFile.updateFileData("approved");
    }

    // Test processData when fileData is set to "approved"
    function testProcessDataApproved() public {
        safeFile.updateFileData("approved");
        string memory result = safeFile.processData();
        assertEq(result, "File approved", "processData should return 'File approved' when fileData is approved");
    }

    // Test processData when fileData is not set to "approved"
    function testProcessDataNotApproved() public {
        safeFile.updateFileData("denied");
        string memory result = safeFile.processData();
        assertEq(result, "File not approved", "processData should return 'File not approved' when fileData is not approved");
    }
}
