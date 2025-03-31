pragma solidity >=0.8.0;
// SPDX-License-Identifier: UNLICENSED

/*
  修正：Bad Randomness 修正後版本
  描述：為了避免直接操作 blockhash 被攻擊者利用，我們加入至少 5 個區塊的延遲，
        使得下注時的 blockhash 在 settle 時難以預知，且若超過 256 區塊則視為票券過期。
  此外，修正版依然保留遊戲邏輯，但確保攻擊者無法有效利用前知資訊預測答案。

  部署流程：
    1. 部署 GameGuessBlockFixed 並充值足夠的 Ether 作為獎金庫。
    2. 玩家呼叫 bet() 下註，並提供猜測值 (由正常隨機來源提供，非礦工可控制)。
    3. 至少等待 5 個區塊後，呼叫 settle() 判斷是否中獎。
*/

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
        attempts[msg.sender].blockNumber = 0;
        if (attempts[msg.sender].guess == answer) {
            payable(msg.sender).transfer(2 ether);
        }
    }

    // 允許接收 Ether
    receive() external payable {}
}

/*
  模擬攻擊者嘗試利用漏洞的攻擊合約 (僅供示範)
  注意：在修正版本中，由於需要等待至少 5 個區塊，再加上攻擊者無法預先得知真正的 blockhash，
        此攻擊合約無法有效利用漏洞取得中獎。
*/

contract AttackGameGuessBlockFixed {
    GameGuessBlockFixed public target;
    address public owner;

    // 修改建構子參數轉換：採用 payable 將 address 轉換成合約型別
    constructor(address _target) {
        target = GameGuessBlockFixed(payable(_target));
        owner = msg.sender;
    }

    // 嘗試下注，但由於延遲機制，攻擊者無法正確預知答案
    function attackBet() public payable {
        require(msg.sender == owner, "Not owner");
        // 即便攻擊者試圖以當前區塊的 blockhash 作為 guess，也因延遲而失效
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
