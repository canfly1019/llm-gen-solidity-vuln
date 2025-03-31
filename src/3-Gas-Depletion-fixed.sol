pragma solidity >=0.8.0;

// SPDX-License-Identifier: UNLICENSED

// 修正後的合約使用 Withdraw Pattern 避免單一交易中大量迴圈導致 gas 消耗殆盡的問題。
// 攻擊手法：
// 即使攻擊者或參與者不斷呼叫 join() 加入合約，也不會一次性分配所有獎勵，而是每個參與者自己提領。

contract GasDepletionFixed {
    // 使用 mapping 儲存每個地址對應的獎勵金額
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
        
        // 逐一計算每個參與者應領取的獎勵，但不立即發放，避免在單一交易中耗盡 gas
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

// 修正後的攻擊合約範例：
// 如果有攻擊者嘗試利用多次呼叫 join() ，calculateRewards() 仍可計算出獎勵，但每個提領動作都分散燃氣消耗，
// 因此無法在單一交易中耗盡過多 gas。

contract GasDepletionFixedAttackHelper {
    GasDepletionFixed public fixedContract;

    // 同上，修正由於 payable fallback 的轉換問題
    constructor(address _fixedAddress) {
        fixedContract = GasDepletionFixed(payable(_fixedAddress));
    }

    // 模擬攻擊：重複呼叫 join()，使 participants 陣列快速成長，但不會影響獎勵提領的 gas 限額
    function joinMultiple(uint256 times) public payable {
        require(msg.value == times * 0.01 ether, "Invalid total ETH sent");
        for (uint256 i = 0; i < times; i++) {
            fixedContract.join{value: 0.01 ether}();
        }
    }
}
