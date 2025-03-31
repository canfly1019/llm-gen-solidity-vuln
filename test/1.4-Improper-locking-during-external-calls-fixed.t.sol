pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/*
   The contract below is the fixed version handling external calls safely via proper locking
   and using the effects-interactions pattern. This test suite checks that the fix prevents
   a potential deadlock (denial-of-service) if an external call fails. 
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
   此合約故意在 fallback 中 revert，以模擬利用外部呼叫失敗（例如拒絕接收資金）的情況。
*/
contract AttackFixed {
    BidFixed public bidContract;

    // 注意：建構子接收 BidFixed 合約地址
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



contract BidFixedTest is Test {
    BidFixed bid;
    AttackFixed attack;

    // Helper: Compute the storage slot key for pendingReturns mapping for an address
    // pendingReturns is declared in slot 3 (state=slot0, highestBidder=slot1, highestBid=slot2, mapping=slot3)
    function _pendingReturnsSlot(address user) internal pure returns (bytes32) {
        return keccak256(abi.encode(user, uint256(3)));
    }

    // deploy a new BidFixed contract and fund it with some ETH
    function setUp() public {
        bid = new BidFixed();
        // Fund the BidFixed contract so that it can send ETH during withdraw
        vm.deal(address(bid), 10 ether);
    }

    // Test that a normal user is able to withdraw funds successfully and that state is not locked
    function testNormalWithdraw() public {
        // Use an address to simulate a normal user
        address user = address(0xABCD);
        uint depositAmount = 1 ether;
        
        // Set pendingReturns for the user directly in storage
        bytes32 slot = _pendingReturnsSlot(user);
        vm.store(address(bid), slot, bytes32(uint256(depositAmount)));
        
        // Get initial balance of the user, and ensure user can receive ETH
        uint initialBalance = user.balance;
        
        // Impersonate the user for calling withdraw
        vm.prank(user);
        bid.withdraw();
        
        // Check that the user has received the depositAmount
        uint finalBalance = user.balance;
        assertEq(finalBalance - initialBalance, depositAmount, "User did not receive correct amount");
        
        // Check that pendingReturns for user is now zero
        uint pending = bid.pendingReturns(user);
        assertEq(pending, 0, "pendingReturns not reset to 0");
        
        // The contract state should be unlocked (F)
        uint stateVal = uint(bid.state());
        assertEq(stateVal, 0, "Contract state did not unlock after withdraw");
    }

    // Test that if an external call fails (due to reverting fallback in an attack contract),
    // the contract does not get permanently locked and the pendingReturns remain available.
    function testAttackWithdrawRevertsAndDoesNotLock() public {
        // Deploy the attack contract using a distinct EOA for deployment
        vm.prank(address(0xBEEF));
        attack = new AttackFixed(payable(address(bid)));

        uint depositAmount = 1 ether;
        // Set pendingReturns for the attack contract
        bytes32 slot = _pendingReturnsSlot(address(attack));
        vm.store(address(bid), slot, bytes32(uint256(depositAmount)));

        // We need to ensure the BidFixed contract has enough ETH to complete the transfer attempt
        // (already funded in setUp)

        // Expect the revert from the attack contract's fallback
        vm.prank(address(0xBEEF));
        vm.expectRevert(bytes("Attack contract rejects funds"));
        attack.attackWithdraw();

        // After revert, the state should be unlocked and pendingReturns should remain unchanged
        uint stateVal = uint(bid.state());
        assertEq(stateVal, 0, "Contract state remains locked after failed withdraw");

        // Because withdraw reverted, pendingReturns remains unchanged
        uint pending = bid.pendingReturns(address(attack));
        assertEq(pending, depositAmount, "pendingReturns should remain after failed withdraw");
    }

    // Test that even if a withdraw attempt fails due to an external call reverting, a subsequent successful withdraw can occur
    function testReattemptWithdrawAfterFailure() public {
        // Deploy the attack contract
        vm.prank(address(0xC0DE));
        attack = new AttackFixed(payable(address(bid)));
        
        uint depositAmount = 1 ether;
        // Set pendingReturns for the attack contract
        bytes32 slot = _pendingReturnsSlot(address(attack));
        vm.store(address(bid), slot, bytes32(uint256(depositAmount)));

        // First withdraw attempt using the attack contract will revert
        vm.prank(address(0xC0DE));
        vm.expectRevert(bytes("Attack contract rejects funds"));
        attack.attackWithdraw();

        // Now, simulate that the attack contract corrected its behavior (for example, by forwarding funds to an EOA)
        // To simulate this, we modify the attack contract's fallback at the testing level by impersonating the user,
        // and we update pendingReturns for a normal user instead.

        // Set pendingReturns for a normal user
        address user = address(0xDEAD);
        bytes32 slotUser = _pendingReturnsSlot(user);
        vm.store(address(bid), slotUser, bytes32(uint256(depositAmount)));

        // Record initial balance
        uint initialBalance = user.balance;
        vm.prank(user);
        bid.withdraw();
        uint finalBalance = user.balance;
        assertEq(finalBalance - initialBalance, depositAmount, "User did not receive funds after reattempting withdraw");

        // Final state check: state should be unlocked
        uint stateVal = uint(bid.state());
        assertEq(stateVal, 0, "Contract state not unlocked after successful withdraw");
    }
}
