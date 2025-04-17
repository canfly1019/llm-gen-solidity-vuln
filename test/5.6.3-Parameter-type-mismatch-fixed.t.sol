pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/5.6.3-Parameter-type-mismatch-fixed.sol";

contract ParameterTypeMismatchFixedTest is Test {
    Wallet wallet;
    GoodToken goodToken;
    AttackFixed attackFixed;

    function setUp() public {
        // Deploy the Wallet contract
        wallet = new Wallet();
        // Deploy a GoodToken instance (for direct wallet calls)
        goodToken = new GoodToken();
        // Deploy the AttackFixed contract which uses the deployed Wallet, and internally deploys a GoodToken
        attackFixed = new AttackFixed(wallet);
    }

    function testDirectWalletTransfer() public {
        // This test calls Wallet.transfer directly with a properly typed uint32
        // The GoodToken instance returns true for transfer so no revert should occur.
        // Using a value within uint32 range
        uint32 value = 123;
        wallet.transfer(address(goodToken), value);
    }

    function testAttackFixedExecuteAttack() public {
        // This test calls AttackFixed.executeAttack which internally calls wallet.transfer
        // As the parameter types are consistent, the call should follow the intended flow without exploitable behavior.
        uint32 value = 456;
        attackFixed.executeAttack(value);
    }

    function testInterfaceConsistency() public {
        // This test ensures that the function selector for transfer(uint32) in the interface
        // matches the one in GoodToken. This confirms that the parameter types are consistent.
        bytes4 selectorInterface = Token.transfer.selector;
        bytes4 selectorGoodToken = GoodToken.transfer.selector;
        assertEq(selectorInterface, selectorGoodToken, "Function selectors mismatch");
    }
}
