// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
   修正後版本：使用 msg.sender 進行權限檢查，避免漏洞利用
   說明：原先的漏洞在於使用 tx.origin 來判斷 function caller 身份，在修正後版本中，
         我們將檢查條件修改為 msg.sender ，這樣只有直接呼叫合約的擁有者才能成功執行轉帳功能。

   注意：此版本同樣修正了編譯問題，將 AttackWalletFixed 合約中的 userWalletAddr 宣告為 address payable。
   測試步驟：
    1. 部署 FixedUserWallet 並由 owner 儲存 Ether。
    2. 若嘗試以 AttackWalletFixed 或其他中介合約呼叫 transfer 函式，將因 msg.sender 不符而失敗。
*/

contract FixedUserWallet {
    // 狀態變數：擁有者
    address payable public owner;

    // 建構子，設定部署者為擁有者，並可接收 Ether
    constructor() payable {
        owner = payable(msg.sender);
    }

    // 修正後的 transfer 函式：使用 msg.sender 進行權限驗證
    function transfer(address payable dest, uint256 amount) public {
        // 修正重點：檢查直接呼叫者是否為 owner
        require(msg.sender == owner, "Not owner");
        dest.transfer(amount);
    }

    // 接收 Ether 的 receive 函式
    receive() external payable {}
}

// 模擬攻擊合約：即使攻擊者透過攻擊合約呼叫也會失敗，因為 msg.sender 為攻擊合約而非 owner
contract AttackWalletFixed {
    // 將 userWalletAddr 宣告為 address payable
    address payable public userWalletAddr;
    address public thiefAddr;

    // 設定 FixedUserWallet 的地址和攻擊者控制的地址
    constructor(address payable _userWalletAddr, address _thiefAddr) {
        userWalletAddr = _userWalletAddr;
        thiefAddr = _thiefAddr;
    }

    // fallback 函式：嘗試透過中介呼叫 FixedUserWallet.transfer
    fallback() external payable {
        FixedUserWallet w = FixedUserWallet(userWalletAddr);
        // 此呼叫將因為 msg.sender 不為 owner 而失敗
        w.transfer(payable(thiefAddr), address(this).balance);
    }

    // 接收 Ether 的 receive 函式
    receive() external payable {}
}
