pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the contract we want to test
// Assuming the contract code is included in the same project

contract TestStorageFixed {
    uint constant constuint = 16;
    mapping (address => uint) public uints1;

    // Setter mapping is now private
    mapping (address => DeviceData) private structs1;

    // Private arrays
    uint[] private uintarray;
    DeviceData[] private deviceDataArray;

    // Struct definition
    struct DeviceData {
        string deviceBrand;
        string deviceYear;
        string batteryWearLevel;
    }

    // Function to initialize and store data
    function testStorage() public {
        // Using proper checksum addresses
        address address1 = 0xbCcc714d56bc0da0fd33d96d2a87b680dD6D0DF6;
        address address2 = 0xaee905FdD3ED851e48d22059575b9F4245A82B04;

        uints1[address1] = 88;
        uints1[address2] = 99;

        DeviceData memory dev1 = DeviceData("deviceBrand", "deviceYear", "wearLevel");
        structs1[address1] = dev1;

        uintarray.push(8000);
        uintarray.push(9000);

        deviceDataArray.push(dev1);
    }

    // Controlled getter for uintarray length
    function getUintArrayLength() public view returns (uint) {
        return uintarray.length;
    }

    // Controlled getter for deviceDataArray length
    function getDeviceDataArrayLength() public view returns (uint) {
        return deviceDataArray.length;
    }
}


contract TestStorageFixedTest is Test {
    TestStorageFixed public testContract;

    // Setup is executed before every test
    function setUp() public {
        testContract = new TestStorageFixed();
    }

    function testPublicMappingAccess() public {
        // Call testStorage to initialize data
        testContract.testStorage();

        // Given addresses
        address address1 = 0xbCcc714d56bc0da0fd33d96d2a87b680dD6D0DF6;
        address address2 = 0xaee905FdD3ED851e48d22059575b9F4245A82B04;

        // Verify that public mapping returns the correct values
        uint value1 = testContract.uints1(address1);
        uint value2 = testContract.uints1(address2);

        assertEq(value1, 88, "uints1 mapping for address1 should be 88");
        assertEq(value2, 99, "uints1 mapping for address2 should be 99");
    }

    function testPrivateArrayLengths() public {
        // Call testStorage to initialize data
        testContract.testStorage();
        
        // Verify that the controlled getter returns the correct array lengths
        uint uintArrayLength = testContract.getUintArrayLength();
        uint deviceDataArrayLength = testContract.getDeviceDataArrayLength();

        assertEq(uintArrayLength, 2, "uintarray should have length 2");
        assertEq(deviceDataArrayLength, 1, "deviceDataArray should have length 1");
    }

    function testInaccessiblePrivateVariables() public {
        // This test attempts to confirm that private variables are not accessible via the ABI
        // If a developer mistakenly declares a variable with internal default visibility, we could call it.
        // In this fixed version, the private variables do not expose any ABI, so these calls should fail.
        // We simulate this by using low-level calls to non-existing getter functions.

        // Attempt to access a getter for 'uintarray'. Since it's private, it should not exist.
        (bool successUintArray, ) = address(testContract).call(abi.encodeWithSignature("uintarray(uint256)", 0));
        assertTrue(!successUintArray, "Accessing private uintarray should fail");

        // Attempt to access a getter for 'structs1'. Since it's private, it should not exist.
        (bool successStructs, ) = address(testContract).call(abi.encodeWithSignature("structs1(address)", address(0)));
        assertTrue(!successStructs, "Accessing private structs1 mapping should fail");

        // Attempt to access a getter for 'deviceDataArray'. Since it's private, it should not exist.
        (bool successDeviceDataArray, ) = address(testContract).call(abi.encodeWithSignature("deviceDataArray(uint256)", 0));
        assertTrue(!successDeviceDataArray, "Accessing private deviceDataArray should fail");
    }
}
