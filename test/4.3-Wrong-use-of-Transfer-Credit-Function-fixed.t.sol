pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The fixed Auction contract using the Withdraw Pattern
contract AuctionFixed {
    address public highestBidder;
    uint public highestBid;
    
    // Mapping to record refund amounts
    mapping(address => uint) public refunds;

    // Bid function
    function bid() external payable {
        require(msg.value >= highestBid, "Bid not high enough");
        if (highestBidder != address(0)) {
            // Instead of sending refund immediately, record it
            refunds[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
    }
    
    // Withdraw refund function
    function withdrawRefund() external {
        uint refund = refunds[msg.sender];
        require(refund > 0, "No refund available");
        refunds[msg.sender] = 0;
        payable(msg.sender).transfer(refund);
    }

    // Allow contract to receive Ether
    receive() external payable {}
}

// Attack contract that always reverts on receiving ether
contract AttackFixed {
    AuctionFixed public auctionFixed;
    
    constructor(address payable _auctionAddress) {
        auctionFixed = AuctionFixed(_auctionAddress);
    }
    
    // Function to enter bidding via this contract
    function attackBid() external payable {
        require(msg.value > 0, "Must send some ETH");
        auctionFixed.bid{value: msg.value}();
    }
    
    // Fallback functions that always revert to simulate a contract that rejects refunds
    fallback() external payable {
        revert("AttackFixed: Rejecting refund");
    }
    
    receive() external payable {
        revert("AttackFixed: Rejecting refund");
    }
}


// Forge test contract
contract AuctionFixedTest is Test {
    AuctionFixed auctionFixed;
    AttackFixed attackFixed;

    // Use distinct addresses for attacker and a valid bidder that is an EOA (i.e., without code)
    address attacker;
    address validBidder;

    // setUp runs before each test
    function setUp() public {
        auctionFixed = new AuctionFixed();
        attacker = vm.addr(1);
        validBidder = vm.addr(2);

        // Deploy the attack contract from the attacker address
        vm.prank(attacker);
        attackFixed = new AttackFixed(payable(address(auctionFixed)));
    }

    // Allow this test contract to receive Ether as well
    receive() external payable {}

    // Test that auction remains functional even if an attack contract is used
    function testAuctionRemainsFunctionalDespiteAttack() public {
        // Attacker bids via the AttackFixed contract
        vm.deal(attacker, 5 ether);
        vm.prank(attacker);
        attackFixed.attackBid{value: 1 ether}();
        
        // Confirm highestBid and highestBidder are set to the attack contract
        assertEq(auctionFixed.highestBid(), 1 ether);
        assertEq(auctionFixed.highestBidder(), address(attackFixed));
        
        // Now, a valid bidder (EOA) places a higher bid
        vm.deal(validBidder, 5 ether);
        vm.prank(validBidder);
        auctionFixed.bid{value: 2 ether}();
        
        // Check that highest bidder is updated, and the refund for the attack contract is recorded
        assertEq(auctionFixed.highestBid(), 2 ether);
        assertEq(auctionFixed.highestBidder(), validBidder);
        uint recordedRefund = auctionFixed.refunds(address(attackFixed));
        assertEq(recordedRefund, 1 ether);
    }

    // Test that withdrawRefund reverts for the attack contract because its fallback reverts
    function testWithdrawRefundRevertsForAttackContract() public {
        // Attacker bids using the attack contract
        vm.deal(attacker, 5 ether);
        vm.prank(attacker);
        attackFixed.attackBid{value: 1 ether}();
        
        // A valid bidder outbids the attack contract
        vm.deal(validBidder, 5 ether);
        vm.prank(validBidder);
        auctionFixed.bid{value: 2 ether}();
        
        // The refund for the attack contract should be 1 ether, but any attempt by it to withdraw will revert
        vm.prank(address(attackFixed));
        vm.expectRevert("AttackFixed: Rejecting refund");
        auctionFixed.withdrawRefund();
    }

    // Test that a valid bidder (EOA without code) can successfully withdraw their refund
    function testWithdrawRefundForValidBidder() public {
        // Instead of using the test contract's address (which is a contract), we use an EOA address generated via vm.addr
        address validEOA = vm.addr(3);

        // validEOA places an initial bid
        vm.deal(validEOA, 5 ether);
        vm.prank(validEOA);
        auctionFixed.bid{value: 1 ether}();
        
        // Another bidder outbids validEOA
        address otherBidder = vm.addr(4);
        vm.deal(otherBidder, 5 ether);
        vm.prank(otherBidder);
        auctionFixed.bid{value: 2 ether}();
        
        // Confirm that validEOA is entitled to a refund of 1 ether
        uint refundAmount = auctionFixed.refunds(validEOA);
        assertEq(refundAmount, 1 ether);
        
        // Record the balance of validEOA before withdrawal
        uint initialBalance = validEOA.balance;
        
        // Withdraw refund from validEOA; since validEOA is an EOA (has no code), the transfer should succeed
        vm.prank(validEOA);
        auctionFixed.withdrawRefund();
        
        // Check that the refund mapping is now cleared
        uint postRefund = auctionFixed.refunds(validEOA);
        assertEq(postRefund, 0);
        
        // Check that validEOA's balance increased by the refunded amount
        // Note: Since we're in a simulation, gas costs are not deducted from EOA balances
        uint finalBalance = validEOA.balance;
        assertEq(finalBalance - initialBalance, 1 ether);
    }
}
