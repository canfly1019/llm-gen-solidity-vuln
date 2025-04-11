// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/6.1.7-Exposed-state-variables-fixed.sol";

contract ExposedStateVariablesFixedTest is Test {
    StatefulFixed fixedContract;
    AttackFixed attackContract;

    // We'll deploy the fixed contract with some ether
    function setUp() public {
        // Deploy the fixed contract with 1 ether
        fixedContract = new StatefulFixed{value: 1 ether}();
    }

    // Test that calling exploit() directly reverts because the vulnerable flag is false and cannot be externally changed
    function testDirectExploitReverts() public {
        // Expect the call to revert with the error message since vulnerable is false
        vm.expectRevert(bytes("Error: Not authorized"));
        fixedContract.exploit(payable(address(1)));
    }

    // Test that attempting to attack via the AttackFixed contract fails
    function testAttackContractFails() public {
        // Deploy the attacker contract with the instance of the fixed contract
        attackContract = new AttackFixed(fixedContract);

        // Since the exploit function should revert, we expect a revert on the attack attempt.
        vm.expectRevert(bytes("Error: Not authorized"));
        attackContract.attack();

        // Verify that the fixed contract's balance remains intact (should still be 1 ether)
        uint256 contractBalance = address(fixedContract).balance;
        assertEq(contractBalance, 1 ether, "The fixed contract balance should remain unchanged");
    }

    // Additional test: even if we try to call exploit via low-level call from a different address, it should revert
    function testLowLevelExploitCallReverts() public {
        // Using a VM prank from a different address to simulate an external call
        address attacker = address(2);
        vm.prank(attacker);
        vm.expectRevert(bytes("Error: Not authorized"));
        fixedContract.exploit(payable(attacker));
    }

    // Ensure that the fallback (receive) function works normally for receiving Ether
    function testReceiveEther() public {
        // Send additional ether to the contract
        (bool success, ) = address(fixedContract).call{value: 0.5 ether}('');
        require(success, "Failed to send Ether");

        uint256 expectedBalance = 1 ether + 0.5 ether;
        assertEq(address(fixedContract).balance, expectedBalance, "The contract should have received Ether correctly");
    }
}
