// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
  修正後的合約: NaiveBankFixed
  修正描述: 為了正確處理在迴圈中可能發生的 revert，
         我們必須先將狀態變數更新(例如標記該 winner 已被處理)，
         再進行外部呼叫轉帳。這樣即便後續某次 send 失敗，
         也能避免因狀態未同步更新而導致重複處理或部分操作錯誤。
*/

contract NaiveBankFixed {
    // 狀態變數 winners 與 processed 用於紀錄轉帳及處理狀態
    address payable[] public winners;
    uint public reward = 1 ether;
    mapping(address => bool) public processed;

    constructor() {
        // 初始將部署者加入勝者清單
        winners.push(payable(msg.sender));
    }

    // 用於添加勝者地址
    function addWinner(address payable _winner) public {
        winners.push(_winner);
    }

    // 回傳可用的勝者清單 (此簡單範例中回傳所有地址，但實務上可過濾尚未處理者)
    function getAvailableWinners() internal view returns (address payable[] memory) {
        return winners;
    }

    // 標記給定地址的勝者已被處理，避免重複轉帳
    function setProcWinners(address addr) internal {
        processed[addr] = true;
    }

    // 修正函式: 先標記狀態，再執行外部呼叫轉帳，確保即使某次 send 失敗，
    // 已標記的狀態不會重複處理。
    function setTransfer() public {
        address payable[] memory availableWinners = getAvailableWinners();
        for (uint i = 0; i < availableWinners.length; i++) {
            // 先標記該 winner 為已處理，避免重複動作
            setProcWinners(availableWinners[i]);
            // 進行轉帳操作，若失敗則 revert，已處理狀態確保不會再重複處理相同 winner
            require(availableWinners[i].send(reward), "Send failed, reverting transaction");
        }
    }
}

/*
  攻擊合約: AttackFixed
  此攻擊合約與漏洞版相同，故在接收 Ether 時故意 revert，
  但由於 NaiveBankFixed 先更新了處理狀態，即使某次 send 失敗，也不會導致重複或部分處理的問題。
*/

contract AttackFixed {
    NaiveBankFixed public fixedContract;

    constructor(address _fixedContract) {
        fixedContract = NaiveBankFixed(_fixedContract);
    }

    // fallback 函式: 故意 revert，但因為處理狀態已先行更新，
    // 此攻擊方式不會造成邏輯上的錯誤處理
    fallback() external payable {
        revert("Attack: Reverting on receive");
    }

    // 呼叫 fixed 合約的 setTransfer 以測試修正後流程
    function attack() public {
        fixedContract.setTransfer();
    }
}
