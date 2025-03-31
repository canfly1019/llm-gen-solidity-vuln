pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Include the contracts which we are testing

// Simulated SafeLibrary (trusted)
library SafeLibrary {
    function doSomething(uint x) external pure returns (uint) {
        return x; // correctly returns the input
    }
}

// Fixed contract using SafeLibrary
contract ExampleLibrary {
    uint public data;

    function updateData(uint _data) public {
        data = SafeLibrary.doSomething(_data);
    }

    // Receive and fallback functions to properly receive Ether
    receive() external payable {}
    fallback() external payable {}
}

// Attack example contract: attempts to misuse the contract but will fail to cause manipulation
contract AttackExample {
    ExampleLibrary public victim;

    constructor(address payable _victim) {
         victim = ExampleLibrary(_victim);
    }

    function attack() public {
         victim.updateData(10);
         // Even though this is the attack, the victim's data remains correctly set to 10
    }
}

contract TestExampleLibrary is Test {
    ExampleLibrary victim;
    AttackExample attacker;

    function setUp() public {
        // Deploy the victim contract
        victim = new ExampleLibrary();
    }

    function testUpdateDataDirectly() public {
        // Test that calling updateData with a normal value correctly sets the state
        uint input = 42;
        victim.updateData(input);
        uint stored = victim.data();
        assertEq(stored, input, "The victim.data should equal the input value");
    }

    function testAttackDoesNotManipulateData() public {
        // Deploy the attack contract pointing to our victim
        attacker = new AttackExample(payable(address(victim)));
        // Perform the attack, which internally calls victim.updateData(10)
        attacker.attack();
        uint stored = victim.data();
        // Even though the attacker tried to manipulate the library function, data should be exactly 10
        assertEq(stored, 10, "The victim.data should be exactly 10 after the attack attempt");
    }

    function testAttackWithDifferentValues() public {
        // Verify that even if attacker tries different values through direct call, safe library doesn't alter the value
        uint input = 100;
        victim.updateData(input);
        uint stored = victim.data();
        assertEq(stored, input, "The victim.data should exactly equal the input value (100)");
    }
}
