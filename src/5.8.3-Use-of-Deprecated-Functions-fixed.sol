// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
    修正後的程式碼：DeprecatedSimpleFixed
    修正重點：
    1. 替換已過時的函式為推薦用法：
       - sha3 改為 keccak256
       - throw 改為 revert/require
       - callcode 改為 delegatecall，並謹慎使用
       - var 改為明確型別宣告
       - suicide 改為 selfdestruct
    2. 使用 Solidity >=0.8.0 的語法定義 fallback 與 receive 函式。
    3. 修正攻擊合約中對 payable contract 的引用問題，避免編譯錯誤（例如：明確指定 address 為 payable）。
*/

contract DeprecatedSimpleFixed {
    // 修正後的函式：採用推薦用法並檢查每一步，以確保安全性
    function useDeprecatedFixed() public {
        // 正確使用 blockhash 來獲取區塊資訊
        bytes32 bhash = blockhash(block.number - 1);
        // 使用 keccak256 取代已廢棄的 sha3
        bytes32 hashofhash = keccak256(abi.encodePacked(bhash));
        
        // 使用 gasleft() 檢查剩餘 gas
        uint gasAmount = gasleft();
        require(gasAmount != 0, "Insufficient gas");
        
        // 謹慎使用 delegatecall 範例，呼叫 dummyFixed
        (bool success, ) = address(this).delegatecall(abi.encodeWithSignature("dummyFixed()"));
        require(success, "Delegatecall failed");
        
        // 使用明確型別的陣列
        uint8[3] memory a = [1, 2, 3];
        
        // 明確指定多變數的型別並賦值
        (bool x, string memory y, uint8 z) = (false, "test", 0);
        
        // 根據需求借用 selfdestruct 功能來銷毀合約，請謹慎處理
        selfdestruct(payable(address(0)));
    }

    // 提供一個 dummyFixed 函式供 delegatecall 測試使用
    function dummyFixed() public pure {}

    // 正確定義可接收 Ether 的 fallback 與 receive 函式
    fallback() external payable {}
    receive() external payable {}
}

// 修正後的攻擊合約：解決了地址轉換問題，確保傳入的地址是 payable 的
contract AttackDeprecatedFixed {
    DeprecatedSimpleFixed public fixedContract;

    // 修改構造器參數類型為 address payable 以符合合約的 payable 要求
    constructor(address payable _fixedAddress) {
        fixedContract = DeprecatedSimpleFixed(_fixedAddress);
    }

    // 攻擊方法：呼叫修正過的 useDeprecatedFixed（若業務邏輯不期望自殺，則應移除此操作）
    function attack() public {
        fixedContract.useDeprecatedFixed();
    }

    // 接收 Ether 的 fallback 與 receive
    fallback() external payable {}
    receive() external payable {}
}
