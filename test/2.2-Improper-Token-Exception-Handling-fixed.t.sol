pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// ERC20 interface
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// FixedTokenHandler contract
contract FixedTokenHandler {
    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    // withdraw function fixed to check the return value of token.transfer
    function withdraw(uint256 amount) external {
        bool success = token.transfer(msg.sender, amount);
        require(success, "transfer failed");
    }
}

// MaliciousToken always returns false on transfer
contract MaliciousToken is IERC20 {
    // dummy implementation for balanceOf
    function balanceOf(address /*account*/) external pure override returns (uint256) {
        return 0;
    }

    // transfer always returns false, simulating a failed transfer
    function transfer(address /*recipient*/, uint256 /*amount*/) external pure override returns (bool) {
        return false;
    }
}

// GoodToken simulates a well-behaving ERC20 token
contract GoodToken is IERC20 {
    mapping(address => uint256) public balances;

    // Allow minting tokens for testing purposes
    function mint(address to, uint256 amount) external {
        balances[to] += amount;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }
    
    // Standard ERC20 transfer: moves tokens from msg.sender to recipient
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        uint256 senderBalance = balances[msg.sender];
        require(senderBalance >= amount, "insufficient balance");
        balances[msg.sender] = senderBalance - amount;
        balances[recipient] += amount;
        return true;
    }
}

contract FixedTokenHandlerTest is Test {
    FixedTokenHandler fixedHandler;
    MaliciousToken maliciousToken;
    GoodToken goodToken;
    address user = address(0xBEEF);

    function setUp() public {
        // Deploy tokens
        maliciousToken = new MaliciousToken();
        goodToken = new GoodToken();
    }

    function testWithdrawRevertsWithMaliciousToken() public {
        // Deploy FixedTokenHandler with maliciousToken address
        fixedHandler = new FixedTokenHandler(address(maliciousToken));

        // Expect revert with "transfer failed"
        vm.expectRevert(bytes("transfer failed"));
        // Use vm.prank so that msg.sender in FixedTokenHandler.withdraw is user
        vm.prank(user);
        fixedHandler.withdraw(100);
    }

    function testWithdrawSucceedsWithGoodToken() public {
        // Deploy FixedTokenHandler with goodToken address
        fixedHandler = new FixedTokenHandler(address(goodToken));

        // To ensure the withdraw succeeds, we need to provide FixedTokenHandler with enough tokens
        // Since FixedTokenHandler calls goodToken.transfer(msg.sender, amount), the tokens are deducted from FixedTokenHandler's balance
        // Mint tokens to FixedTokenHandler
        goodToken.mint(address(fixedHandler), 200);

        // Check initial balances
        uint256 handlerBalanceBefore = goodToken.balanceOf(address(fixedHandler));
        uint256 userBalanceBefore = goodToken.balanceOf(user);
        assertEq(handlerBalanceBefore, 200);

        // Withdraw 100 tokens. The call to withdraw will call goodToken.transfer(user, 100) from FixedTokenHandler
        vm.prank(user);
        fixedHandler.withdraw(100);

        // Check final balances
        uint256 handlerBalanceAfter = goodToken.balanceOf(address(fixedHandler));
        uint256 userBalanceAfter = goodToken.balanceOf(user);

        assertEq(handlerBalanceAfter, handlerBalanceBefore - 100, "Handler balance should decrease by withdrawn amount");
        assertEq(userBalanceAfter, userBalanceBefore + 100, "User balance should increase by withdrawn amount");
    }
}
