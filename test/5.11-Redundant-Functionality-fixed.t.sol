pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The fixed contract: ExRedundantFixed
contract ExRedundantFixed {
    // 儲存累計接收的 Ether 金額
    uint256 public totalReceived;
    
    // 每個地址的存款記錄
    mapping(address => uint256) public balances;

    // 正確使用 receive() 來僅處理空 calldata 的情形
    receive() external payable {
        // 正常接收 Ether，不進行其他處理
    }
    
    // 存款函數
    function deposit() external payable {
        totalReceived += msg.value;
    }
    
    function depositFor() external payable {
        balances[msg.sender] += msg.value;
        totalReceived += msg.value;
    }
}

// 攻擊合約：嘗試利用非空 calldata 發送 Ether，但因合約已移除 fallback()，因此會 revert
contract AttackFixed {
    ExRedundantFixed public fixedContract;
    
    constructor(address payable _fixedAddress) {
        fixedContract = ExRedundantFixed(_fixedAddress);
    }
    
    // 攻擊示例：嘗試發送帶有非空 calldata 的轉帳
    function attack() external payable {
        // 由於合約中不再有 fallback()，帶有非空 calldata 的 call 會找不到对应函數而 revert
        (bool success, ) = address(fixedContract).call{value: msg.value}(abi.encodePacked("attack"));
        require(success, "Attack failed: no fallback exists in fixed contract");
    }
    
    // 正常 deposit 使用：明確呼叫 depositFor() 函數進行操作
    function normalDeposit() external payable {
        fixedContract.depositFor{value: msg.value}();
    }
}

contract TestExRedundantFixed is Test {
    ExRedundantFixed exRedundantFixed;
    AttackFixed attackFixed;

    function setUp() public {
        exRedundantFixed = new ExRedundantFixed();
        // Casting address to payable as required by AttackFixed constructor
        attackFixed = new AttackFixed(payable(address(exRedundantFixed)));
    }

    // Test that an attack using non-empty calldata fails as the fallback function is removed
    function testAttackFails() public {
        uint256 attackValue = 1 ether;
        // Expect attack() to revert with a specific message
        vm.expectRevert(bytes("Attack failed: no fallback exists in fixed contract"));
        attackFixed.attack{value: attackValue}();
    }

    // Test that directly sending a call with non-empty calldata to ExRedundantFixed fails
    function testDirectCallWithNonEmptyCalldataFails() public {
        uint256 sendValue = 0.5 ether;
        // Attempt direct call with non-empty calldata. This should fail because there is no fallback()
        (bool success, ) = address(exRedundantFixed).call{value: sendValue}(abi.encodePacked("non-empty"));
        assertTrue(!success, "Direct call with non-empty calldata should fail");
    }

    // Test depositFor function to ensure it correctly updates totalReceived and balances
    function testDepositFor() public {
        uint256 depositValue = 1 ether;
        uint256 initialTotal = exRedundantFixed.totalReceived();
        // Call depositFor directly on ExRedundantFixed
        exRedundantFixed.depositFor{value: depositValue}();

        uint256 updatedTotal = exRedundantFixed.totalReceived();
        assertEq(updatedTotal, initialTotal + depositValue, "Total received should increase by depositValue");

        // Also check balance for msg.sender (which in this test is address(this))
        uint256 balance = exRedundantFixed.balances(address(this));
        assertEq(balance, depositValue, "Balance for sender should reflect the deposit");
    }

    // Test deposit function to ensure it updates totalReceived correctly
    function testDeposit() public {
        uint256 depositValue = 2 ether;
        uint256 initialTotal = exRedundantFixed.totalReceived();
        exRedundantFixed.deposit{value: depositValue}();

        uint256 updatedTotal = exRedundantFixed.totalReceived();
        assertEq(updatedTotal, initialTotal + depositValue, "Total received should increase by depositValue");
    }

    // Test normal deposit through the AttackFixed contract that explicitly calls depositFor
    function testNormalDepositThroughAttackFixed() public {
        uint256 depositValue = 1 ether;
        uint256 initialTotal = exRedundantFixed.totalReceived();
        
        attackFixed.normalDeposit{value: depositValue}();
        
        uint256 updatedTotal = exRedundantFixed.totalReceived();
        assertEq(updatedTotal, initialTotal + depositValue, "Total received should increase after normalDeposit");
        
        // The balance recorded in ExRedundantFixed for the caller will be that of AttackFixed's address
        uint256 recordedBalance = exRedundantFixed.balances(address(attackFixed));
        assertEq(recordedBalance, depositValue, "AttackFixed's deposit should be recorded correctly via depositFor");
    }
}
