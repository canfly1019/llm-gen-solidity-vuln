// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
  修正方式：
    為避免因交易排序導致轉帳收款者被惡意更改，採用不可變的轉帳邏輯，
    例如利用固定的 wallet library 合約來執行 delegatecall，不直接依賴本合約中的狀態變數。
    此範例其實示意使用了 delegatecall 將 withdraw 的邏輯交由不可變的外部合約處理，
    攻擊者無法在同一區塊內修改關鍵狀態（例如 owner 或收款者地址）。

  注意：
    實際使用中需確保 walletLibrary 的地址正確且安全，並且該 library 已經經過充分審查。
    此範例主要用來示意修正上的概念，同時展示 Solidity >=0.8.0 版本的語法。
*/

contract Wallet {
    // 固定地址的 wallet library，該地址不可被修改
    address constant walletLibrary = 0xb794F5eA0ba39494cE839613fffBA74279579268;

    // 接收 Ether 的函數
    receive() external payable {}

    // withdraw 函數將呼叫委派至固定的 library 合約執行實際的提款邏輯
    // 這樣做可確保流程中不會因交易排序而導致收款者被竄改
    function withdraw() public {
        (bool success, ) = walletLibrary.delegatecall(msg.data);
        require(success, "Delegatecall failed");
    }
}

/*
  修正後的攻擊模擬說明：
    由於 Wallet 合約不包含可被任意修改的狀態變數（例如 owner），
    攻擊者將無法藉由在同一區塊內呼叫任何函數來修改提款接收地址，
    因此交易排序漏洞已獲修復。
    若有測試需求，請部署 Wallet 與對應的 walletLibrary，並模擬正常 withdraw 流程。
*/
