// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
   修正說明：
   為了正確鎖定狀態，我們在執行外部呼叫前，先將狀態設為 InTransition，
   並在外部呼叫前即更新 pendingReturns 狀態，避免 reentrancy 攻擊及 deadlock 問題。
   此外，我們利用 effects-interactions pattern 確保狀態先變更，後進行外部呼叫。
*/

contract BidFixed {
    // 定義合約狀態
    enum State { F, InTransition }
    State public state = State.F;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public pendingReturns;

    function withdraw() public {
        require(state == State.F, "Contract is in transition, try again later");
        
        // 鎖定狀態，避免 reentrancy
        state = State.InTransition;

        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "No pending funds");

        // 先更新狀態變數（effects）
        pendingReturns[msg.sender] = 0;

        // 接著呼叫外部合約（interactions）
        if (msg.sender != highestBidder) {
            payable(msg.sender).transfer(amount);
        } else {
            payable(msg.sender).transfer(amount - highestBid);
        }
        
        // 解鎖狀態
        state = State.F;
    }

    // 接收 ETH 的 fallback 函式
    receive() external payable {}
}

/*
   攻擊合約：
   雖然攻擊合約的 fallback 同樣會 revert，但由於 BidFixed 的 withdraw() 採用 effects-interactions pattern，
   即使外部呼叫失敗也不會阻塞狀態的更新，使用者可重新嘗試 withdraw() 進行提領。
*/

contract AttackFixed {
    BidFixed public bidContract;

    // 修改建構子參數為 address payable 以符合顯式轉換要求
    constructor(address payable _bidContract) {
        bidContract = BidFixed(_bidContract);
    }

    // fallback 故意 revert
    receive() external payable {
        revert("Attack contract rejects funds");
    }

    function attackWithdraw() public {
        bidContract.withdraw();
    }
}
