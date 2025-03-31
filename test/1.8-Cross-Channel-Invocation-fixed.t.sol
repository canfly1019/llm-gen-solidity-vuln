pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the FixedContract. In Foundry, we assume the contract 1.8-Cross-Channel-Invocation-fixed.sol is available in the project.
// For this test, we redefine the contract here for simplicity.

contract FixedContract {
    string public lastMessage;
    address public authorizedChannel;

    constructor(address _authorizedChannel) {
        authorizedChannel = _authorizedChannel;
    }

    modifier onlyAuthorized() {
        require(msg.sender == authorizedChannel, "Not authorized");
        _;
    }

    function updateMessage(string memory _message) public onlyAuthorized {
        lastMessage = _message;
    }

    receive() external payable {}
}


contract FixedContractTest is Test {
    FixedContract fixedContract;

    // Define an authorized channel and an unauthorized address for testing
    address authorizedChannel = address(0x1234);
    address unauthorized = address(0x4321);

    function setUp() public {
        // Deploy the FixedContract with a known authorized channel
        fixedContract = new FixedContract(authorizedChannel);
    }

    function testUpdateMessageAsAuthorized() public {
        // Test that the authorized channel can update the message
        string memory validMessage = "Hello, Authorized Channel!";
        // Simulate call from the authorized channel
        vm.prank(authorizedChannel);
        fixedContract.updateMessage(validMessage);

        // Validate that the state variable was updated
        string memory retrievedMessage = fixedContract.lastMessage();
        assertEq(retrievedMessage, validMessage, "Message should be updated by authorized channel");
    }

    function testUpdateMessageAsUnauthorized() public {
        // Test that an unauthorized caller cannot update the message
        string memory invalidMessage = "Malicious attempt";

        // Expect revert since unauthorized caller is not allowed
        vm.prank(unauthorized);
        vm.expectRevert("Not authorized");
        fixedContract.updateMessage(invalidMessage);
    }

    function testNoSideEffectsOnUnauthorizedCall() public {
        // Ensure that even if an unauthorized call is attempted, the state remains unchanged
        string memory initialMessage = "Initial Message";

        // First, update the message using the authorized channel
        vm.prank(authorizedChannel);
        fixedContract.updateMessage(initialMessage);
        assertEq(fixedContract.lastMessage(), initialMessage);

        // Then, attempt unauthorized update
        vm.prank(unauthorized);
        vm.expectRevert("Not authorized");
        fixedContract.updateMessage("Hacked Message");

        // Confirm that the message remains the one set by the authorized channel
        assertEq(fixedContract.lastMessage(), initialMessage, "Message should remain unchanged after unauthorized call");
    }
}
