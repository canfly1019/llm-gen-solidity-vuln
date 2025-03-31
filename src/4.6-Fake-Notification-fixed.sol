// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
  修正後的程式碼
  說明：
    - 在修正版本中，我們在 eosponser 函式內加入判斷，只有當通知的目標地址為合約自身（address(this)）時，
      才會進一步處理訊息。這避免了攻擊者將 to 參數偽造成受害者地址，進而轉發不當的通知或資金。
    - 若 to 參數不等於合約地址，函式會直接中止，保護合約不會遭受偽造通知攻擊。
*/

contract FixedNotification {
    address public owner;

    event Notified(address indexed from, address indexed to, uint256 quantity, string memo);

    constructor() {
        owner = msg.sender;
    }

    // 修正重點：加入檢查 to 是否為合約本身
    function eosponser(address from, address to, uint256 quantity, string calldata memo) public payable {
        // 若通知目標不為合約自身，則拒絕執行，防止偽造攻擊
        if (to != address(this)) {
            revert("Invalid notification target");
        }
        (bool success, ) = payable(to).call{value: quantity}("");
        require(success, "Transfer failed");

        emit Notified(from, to, quantity, memo);
    }

    // 允許合約接收 Ether
    receive() external payable {}
}

// 嘗試攻擊的合約，攻擊者透過此合約呼叫 FixedNotification 將因檢查失敗而無法成功攻擊
contract AttackFixed {
    FixedNotification public fixedContract;
    address public victim;

    // 同樣處理輸入地址轉換，將 _fixed 轉為 payable 後再轉為 FixedNotification 合約
    constructor(address _fixed, address _victim) {
        fixedContract = FixedNotification(payable(_fixed));
        victim = _victim;
    }

    // 攻擊嘗試函式，由於 to 參數故意設為 victim，將導致函式 revert
    function performAttack() public payable {
        require(msg.value > 0, "Send some ether");
        fixedContract.eosponser{value: msg.value}(msg.sender, victim, msg.value, "Fake notification");
    }
}

/*
  修復說明（繁體中文）：
  修正後的 FixedNotification 合約在 eosponser 函式中加入了檢查，僅允許
  當通知的目標地址為合約自身（address(this)）時才進行後續操作，
  這有效避免了攻擊者利用偽造通知轉發資金或訊息至其他使用者地址的問題。
  AttackFixed 合約中的攻擊嘗試由於使用了不正當的 to 地址，會導致交易 revert。
*/
