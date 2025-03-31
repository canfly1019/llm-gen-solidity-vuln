// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
  修正：改善迴圈內部的例外處理
  說明：
    修改原本在迴圈中直接發送 Ether 的策略，改採 "pull over push" 模式，
    將應該發送的金額記錄在 mapping (credits) 中，由各收款者自行提領。
    這樣做若某個收款者的提款失敗，不會影響其他收款者，從而避免因單一失敗
    造成全部操作回滾，減少不必要的 gas 浪費。

  修正部署與操作說明：
    1. 部署合約時傳入目標地址陣列（可以包含任意地址，包括惡意地址，但不會影響分發).
    2. 呼叫 distribute() 時，每個地址的 "應得 Ether" 將累計到 mapping credits 裡面。
    3. 每個地址可獨立呼叫 withdrawCredits() 自行提領累計的金額。
*/

contract CallInLoopFixed {
    // 狀態變數：存放目標地址（僅供參考，可用來紀錄希望發放補償的地址）
    address[] public destinations;
    
    // 改良方案：使用 mapping 記錄各地址的可提領額度
    mapping(address => uint) public credits;
    
    // 建構子，傳入一個地址陣列
    constructor(address[] memory newDestinations) {
        destinations = newDestinations;
    }
    
    // private 函數，增加 receiver 的可提領金額
    function allowForPull(address receiver, uint amount) private {
        credits[receiver] += amount;
    }
    
    // 分發 Ether 的函式，採取 pull 模式，不直接轉帳給收款者
    function distribute() external payable {
        // 假設 msg.value 必須至少等於 destinations 長度，此處每人累計 1 wei
        require(msg.value >= destinations.length, "Insufficient Ether provided");
        for (uint i = 0; i < destinations.length; i++) {
            // 修改處：不直接轉帳，而是累計 credits
            allowForPull(destinations[i], 1 wei);
        }
        // 將多餘的 Ether 存入合約，如有多餘款項後續可供提款
    }
    
    // 收款者可呼叫此函式提領累計的 credits
    function withdrawCredits() public {
        uint amount = credits[msg.sender];
        require(amount != 0, "No credits available");
        require(address(this).balance >= amount, "Insufficient contract balance");
        // 將領款金額設為 0，避免 reentrancy
        credits[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
    
    // 接收 Ether 的 receive function
    receive() external payable {}
}

/*
  測試與操作步驟：
    1. 部署 CallInLoopFixed 合約，傳入目標地址陣列（可包含正常或惡意地址）。
    2. 呼叫 distribute() 並提供足夠的 Ether，合約將會根據目標地址累計各自應得的 credits。
    3. 各目標地址可分別呼叫 withdrawCredits() 以提領累計的金額。
    4. 即使某個目標地址的提款操作失敗，也不會影響其他地址提領，避免了整體交易失敗的問題。
*/
