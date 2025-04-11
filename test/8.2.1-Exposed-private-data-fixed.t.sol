pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/8.2.1-Exposed-private-data-fixed.sol";

contract OddEvenTest is Test {
    OddEven public game;

    address player1 = address(1);
    address player2 = address(2);
    
    // We'll use some predetermined numbers and blinding factors
    uint constant number1 = 5;
    uint constant number2 = 4;
    bytes32 blindingFactor1 = keccak256(abi.encodePacked("bf1"));
    bytes32 blindingFactor2 = keccak256(abi.encodePacked("bf2"));

    // computed commitments according to the contract's requirement
    bytes32 commitment1;
    bytes32 commitment2;

    function setUp() public {
        // Fund the players with sufficient balance
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        
        // Deploy the contract
        game = new OddEven();

        // Prepare commitments:
        // according to the contract: keccak256(abi.encodePacked(player, number, blindingFactor))
        commitment1 = keccak256(abi.encodePacked(player1, number1, blindingFactor1));
        commitment2 = keccak256(abi.encodePacked(player2, number2, blindingFactor2));
    }

    // Test that in the commit stage, the sensitive number is not exposed in plain text in storage
    function testCommitStagePrivacy() public {
        // Player1 commits
        vm.prank(player1);
        game.play{value: 2 ether}(commitment1);
        
        // Since players is a fixed array of structs, its internal layout is sequential:
        // players[0].addr at slot 0, players[0].commitment at slot 1, players[0].number at slot 2
        // Check that players[0].number is still 0 (not the actual number) at commit stage.
        bytes32 storedNumber = vm.load(address(game), bytes32(uint256(2)));
        assertEq(uint256(storedNumber), 0, "Sensitive number revealed in commit stage");

        // Now player2 commits, transitioning the stage to FirstReveal
        vm.prank(player2);
        game.play{value: 2 ether}(commitment2);
        
        // For player2, players[1].number should be stored at slot 5 (slot 3: addr, 4: commitment, 5: number)
        storedNumber = vm.load(address(game), bytes32(uint256(5)));
        assertEq(uint256(storedNumber), 0, "Sensitive number for player2 revealed in commit stage");
    }

    // Test that an invalid reveal (e.g., wrong blinding factor) is rejected
    function testRevealInvalidBlindingFactor() public {
        // Complete commit phase for player1 and player2
        vm.prank(player1);
        game.play{value: 2 ether}(commitment1);
        vm.prank(player2);
        game.play{value: 2 ether}(commitment2);
        
        // Attempt reveal with wrong blinding factor for player1
        vm.prank(player1);
        vm.expectRevert("invalid hash");
        game.reveal(number1, keccak256(abi.encodePacked("wrong")));
    }

    // Test the full flow: commit, reveal, and distribution work as expected 
    function testFullGameFlow() public {
        uint initialBalancePlayer1 = player1.balance;
        uint initialBalancePlayer2 = player2.balance;

        // Commit phase
        vm.prank(player1);
        game.play{value: 2 ether}(commitment1);
        vm.prank(player2);
        game.play{value: 2 ether}(commitment2);

        // Reveal phase
        vm.prank(player1);
        game.reveal(number1, blindingFactor1);
        vm.prank(player2);
        game.reveal(number2, blindingFactor2);

        // At this point, stage should be Distribution
        assertEq(uint(game.stage()), uint(OddEven.Stage.Distribution));

        // Before distribution, contract balance should be 4 ether
        assertEq(address(game).balance, 4 ether);

        // Determine expected winner: sum = 5+4 = 9, 9 % 2 = 1, so player2 is winner
        
        // Calling distribute from any address (using player1 here for convenience)
        vm.prank(player1);
        game.distribute();

        // After distribution, contract balance should be 0
        assertEq(address(game).balance, 0);

        // Check players balances: 
        // player2 (winner) gets 3 ether; player1 (loser) gets 1 ether refund
        // Note: They each paid 2 ether during commit. 
        // So player1 net change: initial - 2 + 1 = initial - 1
        // And player2 net change: initial - 2 + 3 = initial + 1
        uint finalBalancePlayer1 = player1.balance;
        uint finalBalancePlayer2 = player2.balance;

        // Allow for slight discrepancies due to gas costs in the test environment; however, since we use vm.prank,
        // the cost is not deducted from these accounts in Foundry tests typically.
        assertEq(finalBalancePlayer1, initialBalancePlayer1 - 1 ether, "Incorrect final balance for player1");
        assertEq(finalBalancePlayer2, initialBalancePlayer2 + 1 ether, "Incorrect final balance for player2");
        
        // Additionally verify that after distribution, stage resets to FirstCommit
        assertEq(uint(game.stage()), uint(OddEven.Stage.FirstCommit));
    }
}
