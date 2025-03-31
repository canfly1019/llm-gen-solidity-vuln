pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Copy of the contract under test:

contract Tokensale {
    // 宣告 hardcap 為 public，初始值為 10000 ether
    uint public hardcap = 10000 ether;

    constructor() {}

    // 回傳目前的 hardcap
    function fetchCap() public view returns(uint) {
        return hardcap;
    }
}

contract Presale is Tokensale {
    // 在建構子中直接更新父合約的 hardcap 變數
    constructor() Tokensale() {
        hardcap = 1000 ether;  // 正確更新父合約 hardcap 的值
    }
}

contract AttackFixed {
    // 呼叫 Presale 的 fetchCap()，期望返回 1000 ether
    function attack(address presaleAddress) public view returns (uint) {
        return Presale(presaleAddress).fetchCap();
    }
}


// Forge Foundry 測試
contract UseOfSameNameVariableTest is Test {
    Presale presale;
    AttackFixed attackFixed;

    function setUp() public {
        // 部署 Presale 合約, 建構子將 hardcap 設為 1000 ether
        presale = new Presale();
        // 部署 AttackFixed 合約
        attackFixed = new AttackFixed();
    }

    // 測試 Presale 是否正確更新了 hardcap
    function testPresaleHardcapIsUpdated() public {
        uint cap = presale.fetchCap();
        // 避免任何重命名/覆蓋問題，確保 hardcap 值為 1000 ether
        assertEq(cap, 1000 ether, "hardcap should be updated to 1000 ether");
    }

    // 測試 AttackFixed 調用 attack() 返回正確的 hardcap
    function testAttackFixedReturnsUpdatedHardcap() public {
        uint returnedCap = attackFixed.attack(address(presale));
        assertEq(returnedCap, 1000 ether, "Attack should return updated hardcap of 1000 ether");
    }

    // 測試其他情況，比如直接呼叫 fetchCap()是否正確
    function testDirectFetchCap() public {
        // 呼叫父合約方法，期望的 hardcap 值為 1000 ether
        uint cap = presale.fetchCap();
        assertEq(cap, 1000 ether, "Directly fetching the cap should return 1000 ether");
    }

    // 測試保留以防其他攻擊方式不在此範圍內
    function testNoLocalVariableShadowingAttack() public {
        // 如果該漏洞存在, 則可能會混淆父合約的 state variable
        // 確保硬上限不會是原先的 10000 ether
        uint cap = presale.fetchCap();
        assertTrue(cap != 10000 ether, "hardcap should not be 10000 ether after constructor execution");
    }
}
