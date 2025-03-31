pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Assume the contracts are available from the source file 3-Gas-Depletion-fixed.sol
// We include their definitions here for testing purposes.

contract GasDepletionFixed {
    mapping(address => uint256) public rewards;
    address[] public participants;
    bool public rewardsCalculated = false;

    // 參與者加入合約，支付 0.01 ETH
    function join() public payable {
        require(msg.value == 0.01 ether, "Invalid value");
        participants.push(msg.sender);
    }

    // 獎勵計算函式，僅需呼叫一次
    function calculateRewards() public {
        require(!rewardsCalculated, "Rewards already calculated");
        require(participants.length > 0, "No participants");
        uint256 totalReward = address(this).balance;
        uint256 rewardPerParticipant = totalReward / participants.length;

        // 逐一計算每個參與者應領取的獎勵，但不立即發放
        for (uint i = 0; i < participants.length; i++) {
            rewards[participants[i]] += rewardPerParticipant;
        }
        rewardsCalculated = true;
    }

    // 讓參與者自行提領獎勵
    function withdrawReward() public {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "No reward to withdraw");
        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // 接收 Ether 的 fallback 功能
    receive() external payable {}
}

contract GasDepletionFixedAttackHelper {
    GasDepletionFixed public fixedContract;

    // 使用固定合約地址進行初始化
    constructor(address _fixedAddress) {
        fixedContract = GasDepletionFixed(payable(_fixedAddress));
    }

    // 模擬攻擊：重複呼叫 join()；注意：若攻擊者為合約，必須能接收 ETH。
    function joinMultiple(uint256 times) public payable {
        require(msg.value == times * 0.01 ether, "Invalid total ETH sent");
        for (uint256 i = 0; i < times; i++) {
            fixedContract.join{value: 0.01 ether}();
        }
    }
}

// For testing purposes, we create an AttackHelper that can properly receive Ether
// via a receive() function. This avoids issues when the fixed contract transfers ETH.
contract AttackHelperWithReceive is GasDepletionFixedAttackHelper {
    constructor(address _fixedAddress) GasDepletionFixedAttackHelper(_fixedAddress) {}

    // This receive function allows the helper to receive ETH without reverting
    receive() external payable {}
}


contract GasDepletionFixedTest is Test {
    GasDepletionFixed fixedContract;
    address constant attacker = address(0xBEEF);
    address constant eoaParticipant = address(0xCAFE);

    function setUp() public {
        fixedContract = new GasDepletionFixed();

        // Fund attacker and participant accounts sufficiently.
        vm.deal(attacker, 1 ether);
        vm.deal(eoaParticipant, 1 ether);
    }

    // Test that an attack helper contract can make multiple join() calls without causing gas depletion issues
    // and later can withdraw its reward successfully.
    function testAttackHelperJoinMultiple() public {
        // Deploy the helper contract with receive implemented
        AttackHelperWithReceive helper = new AttackHelperWithReceive(address(fixedContract));

        // As attacker, call joinMultiple with 5 iterations (each 0.01 ETH), total 0.05 ETH.
        vm.prank(attacker);
        helper.joinMultiple{value: 5 * 0.01 ether}(5);

        // The fixed contract's balance should now be 5 * 0.01 = 0.05 ETH
        assertEq(address(fixedContract).balance, 5 * 0.01 ether, "Fixed contract balance mismatch after joins");

        // Calculate rewards; since there's only one participant (the helper), reward should be the entire balance
        fixedContract.calculateRewards();
        uint256 helperReward = fixedContract.rewards(address(helper));
        assertEq(helperReward, 5 * 0.01 ether, "Attack helper reward not accumulated correctly");

        // Record helper's balance before withdrawal
        uint256 helperBalanceBefore = address(helper).balance;

        // As the helper contract (using vm.prank to simulate msg.sender being the helper), withdraw the reward
        vm.prank(address(helper));
        fixedContract.withdrawReward();

        // After withdrawal, the reward mapping for helper should be zero
        uint256 rewardAfterWithdrawal = fixedContract.rewards(address(helper));
        assertEq(rewardAfterWithdrawal, 0, "Reward not zero after withdrawal");

        // The helper's balance should have increased by approximately 0.05 ETH
        uint256 helperBalanceAfter = address(helper).balance;
        assertEq(helperBalanceAfter, helperBalanceBefore + 5 * 0.01 ether, "Attack helper did not receive withdrawn reward");
    }

    // Test that calculateRewards() cannot be called twice
    function testDoubleCalculateRewardsRevert() public {
        // As an EOA participant, join the fixed contract with the correct amount
        vm.prank(eoaParticipant);
        fixedContract.join{value: 0.01 ether}();

        // Ensure there is sufficient balance in the fixed contract
        assertEq(address(fixedContract).balance, 0.01 ether, "Fixed contract balance mismatch after join");

        // Call calculateRewards() the first time; should succeed
        fixedContract.calculateRewards();

        // Calling calculateRewards() a second time should revert with "Rewards already calculated"
        vm.expectRevert(bytes("Rewards already calculated"));
        fixedContract.calculateRewards();
    }
}
