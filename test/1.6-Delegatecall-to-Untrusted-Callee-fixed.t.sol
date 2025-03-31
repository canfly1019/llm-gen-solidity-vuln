pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The fixed Proxy contract
contract ProxyFixed {
    address public callee;
    address public owner;

    constructor() {
        owner = msg.sender;
        callee = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setCallee(address _newCallee) public onlyOwner {
        callee = _newCallee;
    }

    function forward(bytes memory _data) public {
        require(callee != address(0), "callee not set");
        (bool success, ) = callee.delegatecall(_data);
        require(success, "delegatecall failed");
    }
}

// Malicious contract attempting to steal ownership via delegatecall
contract Malicious {
    // pwn attempts to overwrite ProxyFixed.owner (storage slot 0) with caller()
    // Note: In ProxyFixed, slot 0 is actually callee, and slot 1 is owner.  This mismatch illustrates how
    // delegatecall can be dangerous if storage layouts are not aligned. In our fixed contract, only the owner
    // can set the callee, so an attacker cannot force the use of this malicious contract.
    function pwn() public {
        assembly {
            // Overwrite storage slot 0 (which in ProxyFixed holds callee) with caller()
            sstore(0, caller())
        }
    }
}

// A benign contract used for safe delegatecalls. Its function does nothing harmful.
contract Benign {
    // A function that does nothing; used to test delegatecall on a trusted contract.
    function doNothing() public {
        // Intentionally empty
    }
}


contract ProxyFixedTest is Test {
    ProxyFixed proxy;
    Benign benign;
    Malicious malicious;

    address ownerAddress;
    address attacker = address(0xBEEF);

    function setUp() public {
        // Deploy the ProxyFixed contract. The deployer (this contract) is the owner.
        proxy = new ProxyFixed();
        ownerAddress = address(this);

        // Deploy the benign and malicious contracts
        benign = new Benign();
        malicious = new Malicious();
    }

    // Test that only the owner can set the callee address
    function testNonOwnerCannotSetCallee() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        proxy.setCallee(address(malicious));

        // Ensure that callee was not changed
        assertEq(proxy.callee(), address(0));
    }

    // Test that forward reverts if no callee is set
    function testForwardWithoutCallee() public {
        bytes memory data = abi.encodeWithSignature("doNothing()");
        vm.expectRevert(bytes("callee not set"));
        proxy.forward(data);
    }

    // Test that a delegatecall to a trusted (benign) contract does not modify sensitive state
    function testBenignDelegatecallDoesNotAlterSensitiveState() public {
        // Owner sets a trusted callee
        proxy.setCallee(address(benign));
        // Verify callee was set correctly
        assertEq(proxy.callee(), address(benign));
        assertEq(proxy.owner(), ownerAddress);

        // Prepare the call data to invoke benign.doNothing()
        bytes memory data = abi.encodeWithSignature("doNothing()");

        // Let attacker call forward. Even though attacker is calling, the delegatecall
        // will execute benign.doNothing() and not harm the ProxyFixed storage.
        vm.prank(attacker);
        proxy.forward(data);

        // After delegatecall, sensitive state (owner and callee) remains unchanged
        assertEq(proxy.owner(), ownerAddress);
        assertEq(proxy.callee(), address(benign));
    }

    // Test that an attacker cannot abuse delegatecall via setting a malicious callee
    // In this test, we simulate an attacker attempting to set the malicious contract as callee and then
    // call delegatecall to hijack ownership.  The fix prevents the attacker from setting the callee.
    function testMaliciousDelegatecallPrevention() public {
        // Attacker tries to set malicious contract as the callee
        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        proxy.setCallee(address(malicious));

        // Owner sets the callee to a known good contract (e.g., benign) to show that even if forward is called by attacker
        // the delegatecall will not allow unauthorized changes.
        proxy.setCallee(address(benign));

        // Attacker now attempts to call forward with data intended for malicious.pwn() --
        // But since the callee is benign, the malicious behavior is not executed.
        bytes memory maliciousData = abi.encodeWithSignature("pwn()");
        vm.prank(attacker);
        vm.expectRevert(); // Likely revert because benign contract does not have pwn()
        proxy.forward(maliciousData);

        // Sensitive state remains intact
        assertEq(proxy.owner(), ownerAddress);
        assertEq(proxy.callee(), address(benign));
    }
}
