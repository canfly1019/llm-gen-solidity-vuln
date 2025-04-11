pragma solidity ^0.8.0;

// Import Foundry's standard Test library
import "forge-std/Test.sol";

// Import the contract to test
import "../src/8.3.4-Incorrect-Argument-Encoding-fixed.sol";

contract FixedAccessControlTest is Test {
    FixedAccessControl target;
    // This constant is the address returned by ECDSA.recover
    address constant ADMIN_FROM_RECOVER = 0x1234567890123456789012345678901234567890;
    // A sample non-admin address
    address nonAdmin = address(0xBEEF);

    // setUp deploys the FixedAccessControl contract and adds ADMIN_FROM_RECOVER to admin mapping
    function setUp() public {
        target = new FixedAccessControl();
        // As the deployer is admin, use it to add ADMIN_FROM_RECOVER to the admins
        address[] memory admins = new address[](1);
        admins[0] = ADMIN_FROM_RECOVER;
        address[] memory regularUsers = new address[](0);
        // When caller is admin, the signature is not used so empty is fine
        target.addUsers(admins, regularUsers, "");
    }

    // Test that an admin can add new admins and regular users without a valid signature
    function testAddUsersAsAdmin() public {
        address[] memory newAdmins = new address[](1);
        newAdmins[0] = address(0xAbCd);
        address[] memory newRegularUsers = new address[](1);
        newRegularUsers[0] = address(0x1234);

        // Caller is admin so signature is ignored
        target.addUsers(newAdmins, newRegularUsers, "");

        assertTrue(target.isAdmin(newAdmins[0]), "new admin not added");
        assertTrue(target.isRegularUser(newRegularUsers[0]), "new regular user not added");
    }

    // Test that non-admin calls with an invalid signature (i.e., wrong length) revert
    function testAddUsersAsNonAdminRevert() public {
        address[] memory newAdmins = new address[](1);
        newAdmins[0] = address(0xAbCd);
        address[] memory newRegularUsers = new address[](1);
        newRegularUsers[0] = address(0x1234);

        vm.prank(nonAdmin);
        // Expect revert due to invalid signature length (signature length != 65 bytes)
        vm.expectRevert(bytes("invalid signature length"));
        target.addUsers(newAdmins, newRegularUsers, "");
    }

    // Test that a non-admin can add users if a validly sized signature is provided,
    // which, regardless of its content, causes ECDSA.recover to return ADMIN_FROM_RECOVER (an admin)
    function testNonAdminWithValidAdminSignatureScenario() public {
        // Create a dummy signature of valid length (65 bytes)
        bytes memory validSig = new bytes(65); // Default bytes are zeros, length is 65

        address[] memory newAdmins = new address[](1);
        newAdmins[0] = address(0xAbCd);
        address[] memory newRegularUsers = new address[](1);
        newRegularUsers[0] = address(0x1234);

        vm.prank(nonAdmin);
        // Should succeed because recover() returns ADMIN_FROM_RECOVER which has been set as admin
        target.addUsers(newAdmins, newRegularUsers, validSig);

        assertTrue(target.isAdmin(newAdmins[0]), "new admin not added by non-admin with valid signature");
        assertTrue(target.isRegularUser(newRegularUsers[0]), "new regular user not added by non-admin with valid signature");
    }

    // Test the AttackFixed contract which should revert when the signature provided is invalid (wrong length)
    function testAttackFixedRevert() public {
        AttackFixed attacker = new AttackFixed(target);

        vm.prank(nonAdmin);
        // Passing an invalid signature (empty bytes) so that the underlying addUsers call reverts
        vm.expectRevert(bytes("invalid signature length"));
        attacker.performAttack("");
    }
}
