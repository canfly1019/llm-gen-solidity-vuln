pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.6.2-Function-return-type-mismatch-fixed.sol";

contract TokenFixedTest is Test {
    TokenFixed token;
    Aline aline;

    // Note: Aline.tokenId is public and defaults to 0
    function setUp() public {
        token = new TokenFixed();
        aline = new Aline();
    }

    // Test that when the caller is the actual token owner, transfer works (i.e., does not revert)
    function testSuccessfulTransfer() public {
        // Mint token with id 0 to this contract address
        token.mint(0);
        // Confirm token owner
        address owner = token.ownerOf(0);
        assertEq(owner, address(this), "Token owner should be the test contract");

        // Call transfer and expect it to succeed
        aline.transfer(address(token));

        // No state change to check beyond require passing; the absence of revert indicates success
    }

    // Test that transfer reverts when the caller isn't the token owner
    function test_RevertWhenNonOwnerTransfers() public {
        // Mint token with id 0 to address(this)
        token.mint(0);

        // Use a different address for transfer attempt
        address notOwner = address(0xBEEF);

        // Using vm.prank to simulate call from notOwner and expect revert with message "Not owner"
        vm.prank(notOwner);
        vm.expectRevert(bytes("Not owner"));
        aline.transfer(address(token));
    }
}
