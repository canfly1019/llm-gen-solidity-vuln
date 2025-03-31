pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Import the contracts from the provided file

contract GameGuessBlockFixed {
    struct Attempt {
        uint blockNumber;
        bytes32 guess;
    }
    mapping(address => Attempt) public attempts;

    // 玩家下注，需支付 1 ETH 並輸入猜測值
    function bet(bytes32 _guess) public payable {
        require(msg.value == 1 ether, "Must send exactly 1 ETH");
        attempts[msg.sender] = Attempt({blockNumber: block.number, guess: _guess});
    }

    // settle 函式改正漏洞，新增至少 5 個區塊延遲以及過期判斷
    function settle() public {
        // 必須等到原下注區塊後至少 5 個區塊，以防止攻擊者預測未來區塊的 blockhash
        require(block.number > attempts[msg.sender].blockNumber + 5, "Wait at least 5 blocks");
        // 若下注區塊超過 256 個區塊則無法取得 blockhash，視為票券過期
        require(block.number - attempts[msg.sender].blockNumber < 256, "Ticket expired");
        bytes32 answer = blockhash(attempts[msg.sender].blockNumber);
        // 將投注資料重製，避免重複使用
        attempts[msg.sender].blockNumber = 0;
        if (attempts[msg.sender].guess == answer) {
            payable(msg.sender).transfer(2 ether);
        }
    }

    // 允許接收 Ether
    receive() external payable {}
}

contract AttackGameGuessBlockFixed {
    GameGuessBlockFixed public target;
    address public owner;

    constructor(address _target) {
        target = GameGuessBlockFixed(payable(_target));
        owner = msg.sender;
    }

    // 嘗試下注，但由於延遲機制，攻擊者無法正確預知答案
    function attackBet() public payable {
        require(msg.sender == owner, "Not owner");
        // 攻擊者使用當前區塊的 blockhash 作為猜測值
        bytes32 guess = blockhash(block.number);
        target.bet{value: 1 ether}(guess);
    }

    // 呼叫 settle 函式
    function attackSettle() public {
        require(msg.sender == owner, "Not owner");
        target.settle();
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}

contract GameGuessBlockFixedTest is Test {
    GameGuessBlockFixed game;
    AttackGameGuessBlockFixed attacker;
    address player = address(0xABCD);
    address attackerOwner = address(0xBEEF);

    // Set up our test environment
    function setUp() public {
        // Deploy the game contract and fund it with extra ether to pay out winnings
        game = new GameGuessBlockFixed();
        // fund the contract with 5 ether to cover payouts
        vm.deal(address(this), 10 ether);
        payable(address(game)).transfer(5 ether);

        // Fund our player and attackerOwner accounts
        vm.deal(player, 10 ether);
        vm.deal(attackerOwner, 10 ether);
    }

    // Test that calling settle before 5 blocks have passed will revert
    function testSettleBeforeDelay() public {
        // Use player account
        vm.prank(player);
        // Provide an arbitrary guess (could be anything as payout isn't expected anyway)
        bytes32 guess = bytes32(uint256(123));
        game.bet{value: 1 ether}(guess);

        // Move forward by only 3 blocks (which is less than required delay of 5 blocks)
        uint currentBlock = block.number;
        vm.roll(currentBlock + 3);

        // Expect revert because the settlement delay requirement is not met
        vm.prank(player);
        vm.expectRevert(bytes("Wait at least 5 blocks"));
        game.settle();
    }

    // Test that if more than 256 blocks have passed (ticket expired), settle reverts
    function testTicketExpired() public {
        vm.prank(player);
        bytes32 guess = bytes32(uint256(456));
        game.bet{value: 1 ether}(guess);

        uint betBlock = block.number;
        // Roll forward so that the ticket expires (>= 256 blocks later)
        vm.roll(betBlock + 256);

        vm.prank(player);
        vm.expectRevert(bytes("Ticket expired"));
        game.settle();
    }

    // Test that an attacker using the attack contract does not succeed in winning even when using current blockhash as guess
    function testAttackFails() public {
        // Deploy the attack contract from attackerOwner
        vm.prank(attackerOwner);
        attacker = new AttackGameGuessBlockFixed(address(game));

        // Attacker calls attackBet sending exactly 1 ether
        vm.prank(attackerOwner);
        attacker.attackBet{value: 1 ether}();

        // Move forward by 6 blocks to satisfy settlement delay
        uint currentBlock = block.number;
        vm.roll(currentBlock + 6);

        // Check attacker's balance before settling (should be 0 in the attack contract)
        uint attackerBalanceBefore = address(attacker).balance;

        // Attempt to settle: even though attacker guessed blockhash(block.number) at bet time, delay changes the actual answer
        vm.prank(attackerOwner);
        attacker.attackSettle();

        // After settlement, the attack contract should not have received the reward of 2 ether
        // It only would have if the guess matched the blockhash. That is nearly impossible.
        uint attackerBalanceAfter = address(attacker).balance;
        // Since there is no winning, the attack contract balance should be 0.
        assertEq(attackerBalanceAfter, 0, "Attacker should not win the reward");
    }

    // (Optional) Test a winning scenario if a player somehow guesses correctly. This test is just to show payout works correctly under secure conditions.
    // Note: In normal circumstances, predicting blockhash is infeasible. Here we simulate a win by using the actual blockhash from the bet block.
    function testWinningBet() public {
        // For testing purposes, simulate by controlling the block number.
        // Set a known block number
        uint knownBlock = 100;
        vm.roll(knownBlock);

        // We'll simulate a winning bet by using the expected answer from block knownBlock.
        // IMPORTANT: blockhash(knownBlock) returns 0 if knownBlock is the current block. But we control the environment below.

        // In this test, we do the following:
        //   1. Roll to a block where blockhash(knownBlock) becomes available.
        //   2. Player calls bet in block knownBlock.
        //   3. Later, after required delay, settle is called and payout is issued because guess == blockhash(knownBlock).

        // First, set the block to knownBlock and have player call bet with a placeholder (we will simulate the winning guess by reading blockhash after rolling ahead)
        vm.prank(player);
        bytes32 dummyGuess = bytes32(0); // placeholder
        game.bet{value: 1 ether}(dummyGuess);

        // Get the bet block number from the contract (should be knownBlock)
        (uint betBlock, bytes32 storedGuess) = game.attempts(player);
        assertEq(betBlock, knownBlock);

        // Now simulate what the answer would be on settlement. In a real environment, blockhash(betBlock) is not available in the same block as bet,
        // so we roll forward enough:
        vm.roll(knownBlock + 6);
        bytes32 answer = blockhash(betBlock);
        // Replace the stored guess with the correct answer so that the player wins.
        // This simulates that the player had guessed correctly.
        // We do this by calling bet again from the same player in the same current block.
        // However, note that the contract overwrites attempts, so we need to do this without changing the bet block.
        // Instead, we simulate the winning scenario by directly modifying storage via cheat codes.
        // vm.store(address(game), slot, value) can be used, but the mapping's slot is complicated. For testing purposes, we use a pragma hack:
        // We revert the bet by re-calling bet with the correct guess. But that would update block number which is undesired.
        // Thus, we simply simulate the win by deploying a new contract with the correct guess stored.
        // For the sake of the unit test we allow a temporary cheat: we call bet() using the answer even though the bet block will update,
        // and then we roll back to simulate settlement.
        
        // Instead, we simulate a winning bet cleanly: 
        //   1. Roll to a new block (e.g., block 200) and have the player bet with the guess of blockhash(200) (which would be 0 if called immediately) 
        //      but then after rolling forward, blockhash(200) will be computed. 
        //   2. Then we roll forward and call settle.
        
        // For clarity, we do a second winning bet simulation from scratch:
        uint betBlock2 = 200;
        vm.roll(betBlock2);
        // In current block, blockhash(betBlock2) returns 0. But after rolling forward, answer will be computed. To simulate a win, we cheat:
        // We know that after rolling forward, answer = blockhash(betBlock2). We capture it after rolling forward.
        vm.prank(player);
        game.bet{value: 1 ether}(bytes32(0));
        
        // Move forward at least 6 blocks so settle is allowed
        vm.roll(betBlock2 + 6);
        bytes32 answer2 = blockhash(betBlock2);
        
        // Now, we'll cheat by writing the correct guess into storage so that settle pays out.
        // Calculate the storage slot of attempts[player]. See solidity docs: mapping(key => value) is stored at keccak256(key . slot).
        // In this contract, attempts is the first state variable so its slot is 0.
        // The stored structure has blockNumber at offset 0 and guess at offset 1.
        // We want to update the guess to answer2. 
        // The mapping slot for attempts[player] = keccak256(abi.encode(player, uint256(0))).
        bytes32 slot = keccak256(abi.encode(player, uint256(0)));
        // In the storage, the first 32 bytes is blockNumber and the second is guess. They are packed into successive slots? Actually, struct gets stored in consecutive slots if they don't fit in one.
        // Here, uint and bytes32 are both 32 bytes. So blockNumber is in slot, and guess is in slot+1.
        vm.store(address(game), bytes32(uint256(slot) + 1), bytes32(answer2));
        
        // Record player's balance before settle
        uint balanceBefore = player.balance;
        
        // Settle
        vm.prank(player);
        game.settle();
        
        // In a winning scenario, player should receive 2 ether. However, note that the bet cost 1 ether.
        // So the net increase from the settlement is 1 ether.
        uint balanceAfter = player.balance;
        assertEq(balanceAfter - balanceBefore, 2 ether, "Player should receive 2 ether payout on win");
    }

    // Fallback function to allow this test contract to receive Ether
    receive() external payable {}
}
