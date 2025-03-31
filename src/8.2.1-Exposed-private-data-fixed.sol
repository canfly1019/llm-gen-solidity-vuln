pragma solidity >=0.8.0;

// 修正後的合約：利用 commit-reveal 機制隱藏玩家實際數字，降低敏感資料曝光風險
contract OddEven {
    enum Stage {
        FirstCommit,
        SecondCommit,
        FirstReveal,
        SecondReveal,
        Distribution
    }

    struct Player {
        address addr;
        bytes32 commitment; // 玩家提交的雜湊承諾
        uint number;        // 揭示階段公布的數字
    }

    // 雖然 players 陣列仍然設為 private，但 commit-reveal 機制確保在 commit 階段敏感數字不會被曝光
    Player[2] private players;
    Stage public stage = Stage.FirstCommit;

    // commit 階段：玩家提交雜湊承諾，投注 2 ether (1 ether 賭注 + 1 ether 保證金)
    function play(bytes32 commitment) public payable {
        uint playerIndex;
        if (stage == Stage.FirstCommit) {
            playerIndex = 0;
        } else if (stage == Stage.SecondCommit) {
            playerIndex = 1;
        } else {
            revert("only two players allowed in commit stage");
        }
        require(msg.value == 2 ether, "msg.value must be 2 eth");
        players[playerIndex] = Player(msg.sender, commitment, 0);
        if (stage == Stage.FirstCommit) {
            stage = Stage.SecondCommit;
        } else {
            stage = Stage.FirstReveal;
        }
    }

    // reveal 階段：玩家揭露其數字與 blinding factor，以驗證之前的承諾
    function reveal(uint number, bytes32 blindingFactor) public {
        require(stage == Stage.FirstReveal || stage == Stage.SecondReveal, "wrong stage");
        uint playerIndex;
        if (players[0].addr == msg.sender) {
            playerIndex = 0;
        } else if (players[1].addr == msg.sender) {
            playerIndex = 1;
        } else {
            revert("unknown player");
        }
        require(keccak256(abi.encodePacked(msg.sender, number, blindingFactor)) == players[playerIndex].commitment, "invalid hash");
        players[playerIndex].number = number;
        if (stage == Stage.FirstReveal) {
            stage = Stage.SecondReveal;
        } else {
            stage = Stage.Distribution;
        }
    }

    // distribution 階段：計算勝者並分配賭注和保證金
    function distribute() public {
        require(stage == Stage.Distribution, "wrong stage");
        uint n = players[0].number + players[1].number;
        // 勝者收到 3 ether (賭注和對手保證金)
        (bool success1, ) = players[n % 2].addr.call{value: 3 ether}("");
        require(success1, "transfer to winner failed");
        // 輸家取回自己的押金 1 ether
        (bool success2, ) = players[(n + 1) % 2].addr.call{value: 1 ether}("");
        require(success2, "transfer to loser failed");
        delete players;
        stage = Stage.FirstCommit;
    }

    // 接收 Ether 的 fallback 函式
    receive() external payable {}
}

// 攻擊合約示範：
// 在 commit-reveal 機制中，玩家的真實數字直到 reveal 階段才會公布，
// 即使攻擊者使用 web3.eth.getStorageAt 調用查詢 storage，所獲得的 commitment 為 hash 值，
// 無法反推出玩家的原始數字，因此降低了隱私資料被洩露的風險。
contract AttackFixed {
    // 此函式僅示意如何嘗試讀取存儲，但無法破解 commitment 的雜湊值
    function attack(address target) public view returns (bytes32) {
        bytes32 data;
        return data;
    }
    
    receive() external payable {}
}
