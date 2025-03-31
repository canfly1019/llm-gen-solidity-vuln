/* SPDX-License-Identifier: UNLICENSED */
pragma solidity >=0.8.0;

// 修正合約：AuctionFixed 採用 Withdraw Pattern 來處理退款，避免在競標過程中直接退款導致交易失敗

contract AuctionFixed {
    address public highestBidder;
    uint public highestBid;
    
    // 使用 mapping 記錄每個地址應退款金額
    mapping(address => uint) public refunds;

    // 競標函數
    function bid() external payable {
        require(msg.value >= highestBid, "Bid not high enough");
        if (highestBidder != address(0)) {
            // 不直接送出退款，而是記錄應退金額
            refunds[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
    }
    
    // 提款函數，讓使用者能主動提領退款
    function withdrawRefund() external {
        uint refund = refunds[msg.sender];
        require(refund > 0, "No refund available");
        refunds[msg.sender] = 0;
        payable(msg.sender).transfer(refund);
    }

    // 允許合約接收 Ether
    receive() external payable {}
}

// 攻擊合約範例 (AttackFixed)，展示在修正版本下攻擊無法生效
contract AttackFixed {
    AuctionFixed public auctionFixed;
    
    // 修改參數型態為 address payable，以符合 Solidity 0.8.0 要求
    constructor(address payable _auctionAddress) {
        auctionFixed = AuctionFixed(_auctionAddress);
    }

    // 參與競標的函數
    function attackBid() external payable {
        require(msg.value > 0, "Must send some ETH");
        auctionFixed.bid{value: msg.value}();
    }

    // 即使攻擊合約拒絕接收 Ether，也不影響 AuctionFixed 的競標邏輯，因退款為手動提領
    fallback() external payable {
        revert("AttackFixed: Rejecting refund");
    }

    receive() external payable {
        revert("AttackFixed: Rejecting refund");
    }
}

/*
補充說明：
1. 在漏洞程式碼中，Auction 合約使用 transfer() 方法退款，若接收地址拒絕接收 Ether 則導致競標回滾，從而使其他人無法競標。
2. 攻擊合約 Attack 利用此點，透過其 fallback/receive 永遠 revert，藉由成為最高競標者來凍結整個競標程式。
3. 修正版本 AuctionFixed 使用 Withdraw Pattern，將退款記錄並由使用者自行提領，從而避免於競標過程中直接退款影響交易執行。
4. 為避免 Solidity 0.8.0 型別轉換的錯誤，攻擊合約建構子中參數型態改為 address payable。
*/
