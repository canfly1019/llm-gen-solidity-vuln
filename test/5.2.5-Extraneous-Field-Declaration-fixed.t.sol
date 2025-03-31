pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Fixed contract as provided
contract Fixed {
    mapping(address => uint) internal userBalance;

    constructor() payable {
        userBalance[msg.sender] = msg.value;
    }

    function withdraw(uint _amount) public {
        require(userBalance[msg.sender] >= _amount, "Insufficient funds");
        userBalance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function getUserBalance(address _user) public view returns (uint) {
        return userBalance[_user];
    }
}

contract FixedTest is Test {
    Fixed public fixedContract;
    address public owner = address(this);

    // Deploy the contract with an initial balance
    function setUp() public {
        // Deploy the contract with 1 ether
        fixedContract = (new Fixed){value: 1 ether}();
    }

    // Test that the initial deposit is correctly registered
    function testInitialDeposit() public {
        uint balance = fixedContract.getUserBalance(owner);
        assertEq(balance, 1 ether, "Initial deposit not recorded correctly");
    }

    // Test that withdrawal works properly and only affects the mapping
    function testWithdrawal() public {
        // Withdraw 0.5 ether
        uint withdrawAmount = 0.5 ether;
        uint initialContractBalance = address(fixedContract).balance;
        uint initialUserBalance = fixedContract.getUserBalance(owner);

        // Execute withdrawal
        fixedContract.withdraw(withdrawAmount);

        // Check that internal mapping deducted the amount
        uint newUserBalance = fixedContract.getUserBalance(owner);
        assertEq(newUserBalance, initialUserBalance - withdrawAmount, "User balance not reduced correctly");

        // Check that the contract balance decreased accordingly
        uint newContractBalance = address(fixedContract).balance;
        assertEq(newContractBalance, initialContractBalance - withdrawAmount, "Contract balance not reduced correctly");
    }

    // Test that withdraw reverts when trying to withdraw more than available
    function testWithdrawInsufficientFunds() public {
        uint userBalance = fixedContract.getUserBalance(owner);
        uint withdrawAmount = userBalance + 1;

        vm.expectRevert("Insufficient funds");
        fixedContract.withdraw(withdrawAmount);
    }

    // Test that there is no extraneous setter function (like setBalance) that could be used to modify state maliciously.
    // We do this by trying to call a non-existent function selector via low-level call and ensuring it fails.
    function testNoSetBalanceFunction() public {
        // bytes4 selector for setBalance(uint256) -> keccak256("setBalance(uint256)")
        bytes4 selector = bytes4(keccak256("setBalance(uint256)"));
        bytes memory data = abi.encodeWithSelector(selector, 100 ether);
        (bool success, ) = address(fixedContract).call(data);
        // The call should fail since there is no setBalance function
        assertTrue(!success, "Extraneous field setter (setBalance) should not exist");
    }

    // Fallback test to ensure that contract state is only modifiable through provided functions
    function testDirectMappingModificationNotAllowed() public {
        // Even though the mapping is internal, we check that we cannot access it from outside through low-level calls
        // Here we attempt to read a suspected extraneous slot using low-level staticcall using an arbitrary function signature
        // that could indicate direct mapping access, but since there is no such function, it should fail.

        // bytes4 selector for getBalanceDirect() (which does not exist)
        bytes4 selector = bytes4(keccak256("getBalanceDirect()"));
        (bool success, ) = address(fixedContract).staticcall(abi.encodeWithSelector(selector));
        assertTrue(!success, "Direct mapping access should not be available");
    }

    // Receive function to allow contract to handle transfers in test
    receive() external payable {}
}
