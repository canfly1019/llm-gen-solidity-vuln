pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The original contracts from the fixed version
contract Item {
    // Simulated logic: adding a product returns true
    function addProduct() external returns (bool) {
        return true;
    }
}

contract ContractERP {
    uint public orderCount = 0;

    function newPurchaseOrder(Item product) public {
        bool result = product.addProduct();
        require(result, "addProduct failed");
        orderCount++;
    }
}

contract MaliciousItemFixed {
    // Malicious contract that always returns false
    function addProduct() external returns (bool) {
        return false;
    }
}

contract AttackFixed {
    ContractERP public erp;
    MaliciousItemFixed public maliciousItem;

    constructor() {
        erp = new ContractERP();
        maliciousItem = new MaliciousItemFixed();
    }

    // This execution will revert because addProduct returns false
    function executeAttack() public {
        erp.newPurchaseOrder(Item(address(maliciousItem)));
    }
}


contract ContractERPTest is Test {
    ContractERP erp;
    
    // Setup is executed before each test
    function setUp() public {
        erp = new ContractERP();
    }

    // Test that a normal Item returns success and orderCount increments.
    function testNormalPurchaseOrder() public {
        Item normalItem = new Item();
        uint initialCount = erp.orderCount();
        erp.newPurchaseOrder(normalItem);
        uint newCount = erp.orderCount();
        assertEq(newCount, initialCount + 1, "Order count should be incremented");
    }

    // Test that using a malicious item (that returns false) will revert the transaction
    function testMaliciousPurchaseOrderReverts() public {
        MaliciousItemFixed maliciousItem = new MaliciousItemFixed();
        // Expect revert with the correct message
        vm.expectRevert("addProduct failed");
        erp.newPurchaseOrder(Item(address(maliciousItem)));
    }

    // Test AttackFixed's executeAttack function to validate that it indeed reverts as expected.
    function testAttackFixedReverts() public {
        AttackFixed attack = new AttackFixed();
        // Expect revert with the same error trigger from ContractERP
        vm.expectRevert("addProduct failed");
        attack.executeAttack();
        // Additionally, verify that the orderCount in the ERP instance within AttackFixed remains 0
        // Note: Since ERP instance is internal to AttackFixed, we ensure that the attack didn't bypass the check.
        assertEq(attack.erp().orderCount(), 0, "Order count in ERP should remain 0 after failed attack");
    }
}
