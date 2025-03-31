pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The target contract with vulnerability fixed
contract GuessTheNumber {
    uint private _secretNumber; // secret number set by deployer
    event success(string message);
    event wrongNumber(string message);

    // Constructor sets the secret number
    constructor(uint secretNumber) {
        _secretNumber = secretNumber;
    }

    // Fallback to receive Ether
    receive() external payable {}

    // The guess function requiring exactly 1 ether sent and forwarding proper arguments
    function guess(uint n) payable public {
        require(msg.value == 1 ether, "Require exactly 1 ether");
        uint p = address(this).balance;
        // Correct parameter order: (prize, guessed number, guesser)
        checkAndTransferPrize(p, n, payable(msg.sender));
    }

    // Internal function which checks the guess and if correct transfers the prize
    function checkAndTransferPrize(uint p, uint n, address payable guesser) internal returns(bool) {
        if(n == _secretNumber) {
            guesser.transfer(p);
            emit success("You guessed the correct number!");
            return true;
        } else {
            emit wrongNumber("Youve made an incorrect guess!");
            return false;
        }
    }
}

// Attack contract which tries to exploit the previous vulnerability, but now fails since bug is fixed
contract AttackFixed {
    GuessTheNumber public target;
    event AttackResult(bool success);

    // Constructor sets the target contract
    constructor(address payable _target) {
        target = GuessTheNumber(_target);
    }

    // Attack function sends 1 ether and guesses an incorrect number
    function attack() external payable {
        require(msg.value == 1 ether, "Need to send 1 ether for the attack");
        // Provide an incorrect guess
        target.guess{value: 1 ether}(123);
        emit AttackResult(true);
    }

    // Allow this contract to receive Ether
    receive() external payable {}
}

// Foundry test contract focusing on the vulnerability regarding argument order and control characters
contract GuessTheNumberTest is Test {
    // We'll use the test contract itself as a user in the correct guess test. We add an empty receive so that transfers succeed.
    receive() external payable {}

    GuessTheNumber guessContract;

    // Test that a correct guess successfully transfers the entire prize pool to the guesser.
    // The user (this contract) sends 1 ether and guesses the secret correctly. The contract had been funded earlier.
    function testCorrectGuessTransfersPrize() public {
        // Deploy a GuessTheNumber contract with secret = 777.
        guessContract = new GuessTheNumber(777);

        // Fund the contract with additional 5 ether to create a prize pool.
        (bool success, ) = address(guessContract).call{value: 5 ether}("");
        require(success, "Funding failed");

        // Record initial balance of this contract
        uint userBalanceBefore = address(this).balance;

        // Use the correct guess (777) with exactly 1 ether
        // Calling from this contract, which can receive the prize via our payable receive function
        guessContract.guess{value: 1 ether}(777);

        // After a correct guess, the entire prize pool should be transferred out, leaving zero balance in GuessTheNumber
        uint contractBalanceAfter = address(guessContract).balance;
        assertEq(contractBalanceAfter, 0, "Contract balance should be zero after winning prize");

        // The prize pool consisted of the 5 ether funding plus the 1 ether sent with the guess,
        // so the entire 6 ether should have been sent to this contract. Hence net gain is 5 ether.
        uint userBalanceAfter = address(this).balance;
        assertEq(userBalanceAfter, userBalanceBefore - 1 ether + 6 ether, "User balance should increase by the prize pool net gain");
    }

    // Test that an incorrect guess does not transfer the prize, and the contract's balance increases by the sent ether.
    function testIncorrectGuessDoesNotTransferPrize() public {
        // Deploy with secret 777
        guessContract = new GuessTheNumber(777);

        // Fund the contract with 5 ether
        (bool success, ) = address(guessContract).call{value: 5 ether}("");
        require(success, "Funding failed");

        uint initialContractBalance = address(guessContract).balance;
        uint userBalanceBefore = address(this).balance;

        // Make an incorrect guess (123) using exactly 1 ether
        vm.prank(address(this));
        guessContract.guess{value: 1 ether}(123);

        uint finalContractBalance = address(guessContract).balance;
        uint userBalanceAfter = address(this).balance;

        // Since the guess is wrong, no prize is awarded and the contract retains the 1 ether sent
        assertEq(finalContractBalance, initialContractBalance + 1 ether, "Contract balance should increase by 1 ether");
        // The user's balance should have decreased exactly by 1 ether
        assertApproxEqAbs(userBalanceBefore - 1 ether, userBalanceAfter, 1, "User balance should decrease by 1 ether");
    }

    // Test that the attack contract, attempting to exploit parameter reversal using control characters, does not get any prize
    function testAttackFixedNoPrizeAwarded() public {
        // Deploy GuessTheNumber with secret 777
        guessContract = new GuessTheNumber(777);

        // Fund the contract with 4 ether to create an initial prize pool
        (bool success, ) = address(guessContract).call{value: 4 ether}("");
        require(success, "Funding failed");

        // Set up an attacker address with some balance
        address attacker = address(0x2);
        vm.deal(attacker, 100 ether);

        // Deploy the AttackFixed contract from the attacker address
        vm.prank(attacker);
        AttackFixed attackContract = new AttackFixed(payable(address(guessContract)));

        // Record attacker's balance before the attack
        uint attackerBalanceBefore = attacker.balance;

        // Attack: the attack contract sends 1 ether with an incorrect guess (123)
        vm.prank(attacker);
        attackContract.attack{value: 1 ether}();

        // Since the guess is wrong, the GuessTheNumber contract should simply add the 1 ether sent to its balance
        uint contractBalanceAfter = address(guessContract).balance;
        assertEq(contractBalanceAfter, 4 ether + 1 ether, "Contract balance should increase by 1 ether on wrong guess");

        // The attack contract should not receive any prize funds
        uint attackContractBalance = address(attackContract).balance;
        assertEq(attackContractBalance, 0, "Attack contract should not receive any prize");

        // The attacker's external balance should have decreased by exactly 1 ether
        uint attackerBalanceAfter = attacker.balance;
        assertEq(attackerBalanceAfter, attackerBalanceBefore - 1 ether, "Attacker balance should decrease by 1 ether");
    }

    // Allow the test contract to receive Ether in case it is the recipient of a winning guess
    fallback() external payable {}
}
