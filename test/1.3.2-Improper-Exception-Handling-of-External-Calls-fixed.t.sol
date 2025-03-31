pragma solidity ^0.8.0;

import "forge-std/Test.sol";

//////////////////////// Contract Definitions ////////////////////////

// Provider contract interface and implementation
contract Provider {
    function isCustomer(address customer) public virtual returns (bool) {
        return false;
    }
}

// Fixed Service contract that properly checks if provider address is a contract before calling
contract FixedService {
    function getService(address provider, address customer) public {
        // Check if provider address has deployed code
        require(contractExists(provider), "Provider is not a valid contract");
        Provider _provider = Provider(provider);
        // Call external isCustomer method
        if (_provider.isCustomer(customer)) {
            // Service logic would execute if customer is valid
        }
    }

    function contractExists(address _addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

// A legit provider for testing
contract LegitProvider is Provider {
    function isCustomer(address customer) public pure override returns (bool) {
        // For test, any non-zero address is a valid customer
        return customer != address(0);
    }
}

// A malicious provider contract that always reverts when isCustomer is called
contract MaliciousProvider is Provider {
    function isCustomer(address customer) public pure override returns (bool) {
        revert("Malicious");
    }
}

//////////////////////// Foundry Test Contract ////////////////////////

contract FixedServiceTest is Test {

    FixedService internal service;
    LegitProvider internal legitProvider;
    MaliciousProvider internal maliciousProvider;

    function setUp() public {
        service = new FixedService();
        legitProvider = new LegitProvider();
        maliciousProvider = new MaliciousProvider();
    }

    // Test 1: Valid provider that is a proper contract and returns true for valid customer
    function testValidProvider() public {
        // Using a non-zero address as customer
        address customer = address(0x123);
        // LegitProvider's isCustomer returns true when customer is non-zero
        // This call should succeed and not revert
        service.getService(address(legitProvider), customer);
    }

    // Test 2: Using a non-contract address should result in revert
    function testNonContractProvider() public {
        // use an EOA address that is not a deployed contract. Typically address(this) is a contract,
        // so we pick an arbitrary address that we know is not a contract. One way is to use a precomputed
        // address like 0x1 (or create a new one from a known private key) but for this test, we can assume
        // that address(0xBEEF) is not a contract.
        address nonContract = address(0xBEEF);
        address customer = address(0x123);
        vm.expectRevert("Provider is not a valid contract");
        service.getService(nonContract, customer);
    }

    // Test 3: Using a malicious provider that reverts in its isCustomer method
    function testMaliciousProvider() public {
        address customer = address(0x123);
        // Since maliciousProvider is indeed a contract, the contractExists check will pass, but
        // the isCustomer call will revert with "Malicious".
        vm.expectRevert("Malicious");
        service.getService(address(maliciousProvider), customer);
    }
}
