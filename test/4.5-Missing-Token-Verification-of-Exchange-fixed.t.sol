pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Interfaces and contracts from the provided Fixed contract file

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract FixedExchange {
    // tokens[token address][user address] = deposit amount
    mapping(address => mapping(address => uint256)) public tokens;

    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);

    // Deposits token into the exchange
    // note: payable so that msg.value is available
    function depositToken(address token, uint256 amount) public payable {
        require(msg.value == 0, "No Ether allowed");
        require(token != address(0), "Invalid token address");

        uint256 beforeBalance = IERC20(token).balanceOf(address(this));
        
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 afterBalance = IERC20(token).balanceOf(address(this));
        require(afterBalance - beforeBalance == amount, "Token transfer amount mismatch");

        tokens[token][msg.sender] += amount;
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
}

contract RealToken {
    string public name = "RealToken";
    string public symbol = "REAL";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
    }

    function transferFrom(address from, address to, uint256 amount) public {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

contract FakeTokenForFixed {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        // initially no tokens in the contract
        balanceOf[address(this)] = 0;
    }

    // This transferFrom intentionally does nothing so that FixedExchange's balance check fails
    function transferFrom(address, address, uint256) public pure {}
}

contract FixedAttack {
    FixedExchange public fixedExchange;
    FakeTokenForFixed public fakeToken;
    address public owner;

    constructor(FixedExchange _fixedExchange) {
        fixedExchange = _fixedExchange;
        fakeToken = new FakeTokenForFixed();
        owner = msg.sender;
    }

    // Attempts to deposit fake tokens to exploit the exchange
    function executeAttack(uint256 depositAmount) public {
        fixedExchange.depositToken{value: 0}(address(fakeToken), depositAmount);
    }
}

contract FixedExchangeTest is Test {
    FixedExchange fixedExchange;
    RealToken realToken;

    // setUp is called before each test
    function setUp() public {
        fixedExchange = new FixedExchange();

        // Deploy RealToken with an initial supply of 1000 tokens (using 18 decimals)
        realToken = new RealToken(1000 ether);

        // Approve the FixedExchange to transfer tokens on behalf of this contract
        realToken.approve(address(fixedExchange), 100 ether);
    }

    // Test that depositing a real token works as expected
    function testRealTokenDeposit() public {
        uint256 depositAmount = 100 ether;
        uint256 beforeBalance = realToken.balanceOf(address(fixedExchange));

        fixedExchange.depositToken(address(realToken), depositAmount);
        uint256 afterBalance = realToken.balanceOf(address(fixedExchange));

        // Assert that the amount transferred is exactly depositAmount
        assertEq(afterBalance - beforeBalance, depositAmount);

        // Verify the internal deposit mapping was updated
        uint256 userDeposit = fixedExchange.tokens(address(realToken), address(this));
        assertEq(userDeposit, depositAmount);
    }

    // Test that depositing with a fake token fails due to balance check
    function testFakeTokenDepositFails() public {
        FakeTokenForFixed fakeToken = new FakeTokenForFixed();
        uint256 depositAmount = 100 ether;

        // Expect revert due to token transfer mismatch
        vm.expectRevert("Token transfer amount mismatch");
        fixedExchange.depositToken(address(fakeToken), depositAmount);
    }

    // Test that an attack using the FixedAttack contract fails
    function testFixedAttackFails() public {
        FixedAttack fixedAttack = new FixedAttack(fixedExchange);
        uint256 depositAmount = 100 ether;

        // Expect the attack to revert as the fake token does no actual transfer
        vm.expectRevert("Token transfer amount mismatch");
        fixedAttack.executeAttack(depositAmount);
    }
}
