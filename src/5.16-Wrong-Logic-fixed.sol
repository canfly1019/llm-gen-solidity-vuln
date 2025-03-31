// SPDX-License-Identifier: UNLICENSED
// Solidity version >=0.8.0
pragma solidity >=0.8.0;

// 修正後合約：WrongLogicFixed
// 修正描述：在 claimReward() 函式中加入對 hasClaimed 狀態變數的檢查與更新，避免重複領取獎勵，從而避免資金被濫用。

contract WrongLogicFixed {
    // 修正重點：正確使用 hasClaimed 狀態變數，確保每個地址只能領取一次
    mapping(address => bool) public hasClaimed;
    
    uint public reward = 1 ether;
    
    // 合約部署時必須附帶足夠的資金
    constructor() payable {}
    
    // 修正函式：先檢查領取狀態，若未領取則標記後發放獎勵
    function claimReward() public {
        require(!hasClaimed[msg.sender], "Already claimed reward");
        require(address(this).balance >= reward, "Insufficient balance");

        // 標記為已領取
        hasClaimed[msg.sender] = true;
        
        // 轉帳獎勵
        payable(msg.sender).transfer(reward);
    }
    
    // 正確接收 Ether 的 receive 函式
    receive() external payable {}
}

// 攻擊者合約範例：AttackWrongLogicFixed
// 說明：試圖重複呼叫 claimReward() 但由於修正後檢查，只有第一次呼叫成功，之後皆失敗。

contract AttackWrongLogicFixed {
    // 修改參數型別為 address payable，以符合轉換要求
    WrongLogicFixed public fixedContract;

    // 部署時傳入修正後合約的 payable address
    constructor(address payable _fixedContract) {
        fixedContract = WrongLogicFixed(_fixedContract);
    }

    // 攻擊函式：嘗試呼叫 claimReward() (僅能成功一次)
    function attack() public {
        fixedContract.claimReward();
    }

    // 提款函式：將合約內 Ether 提現到呼叫者地址
    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}
