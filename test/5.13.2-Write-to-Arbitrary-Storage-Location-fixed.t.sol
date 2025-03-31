pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the Wallet contract (assuming it's in the same directory)
import "../src/5.13.2-Write-to-Arbitrary-Storage-Location-fixed.sol";

contract WalletTest is Test {
    Wallet wallet;
    address deployer;

    function setUp() public {
        deployer = address(this);
        wallet = new Wallet();
    }

    // Test that calling PopBonusCode on an empty bonusCodes array reverts
    function testPreventPopWhenEmpty() public {
        vm.expectRevert(bytes("No bonus codes to pop"));
        wallet.PopBonusCode();
    }

    // Test that trying to update bonusCodes at an out-of-bound index reverts
    // This is where a malicious user might try to write to a storage slot (e.g. owner's slot)
    function testPreventOutOfBoundsUpdate() public {
        // Push one bonus code so that bonusCodes.length == 1
        wallet.PushBonusCode(42);

        // Attempt to update index 1, which is out-of-bound
        vm.expectRevert(bytes("Index out of bound"));
        wallet.UpdateBonusCodeAt(1, 100);
    }

    // Test that safe pop() does not allow modification of unintended storage slots (i.e. the owner remains unchanged)
    function testSafePopDoesNotAffectOwnerStorage() public {
        // Push a bonus code so that bonusCodes.length becomes 1
        wallet.PushBonusCode(55);
        address ownerBefore = wallet.owner();

        // Pop the only bonus code
        wallet.PopBonusCode();

        // Check that owner value has not been tampered with
        assertEq(wallet.owner(), ownerBefore, "Owner should not be modified after pop");

        // Additionally, try to access bonusCodes at index 0 should now revert since the array is empty
        vm.expectRevert();
        // This call should revert because there is no element at index 0
        wallet.bonusCodes(0);
    }

    // Test that updating a bonus code within bounds works as expected
    function testUpdateBonusCodeWithinBounds() public {
        // Push two bonus codes
        wallet.PushBonusCode(10);
        wallet.PushBonusCode(20);

        // Update bonus code at index 0 with a new value
        wallet.UpdateBonusCodeAt(0, 100);

        // Check the update is applied correctly
        uint updatedCode = wallet.bonusCodes(0);
        assertEq(updatedCode, 100, "Bonus code at index 0 should be updated to 100");
    }
}
