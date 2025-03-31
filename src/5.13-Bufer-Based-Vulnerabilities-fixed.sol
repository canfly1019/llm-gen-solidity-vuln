// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
修正後的程式碼說明：
在修正後的版本中，我們在 writeData 函式中增加了輸入資料長度檢查，
確保傳入的資料長度不會超過預定的 buffer 長度，
從而避免因輸入資料過長導致的 buffer overflow 問題，
避免攻擊者藉此覆寫掉 owner 等重要狀態變數。

修正步驟：
1. 增加 require 檢查，若 _data.length 超過 buffer 長度則 revert。
2. 使用安全的高階語言將資料寫入 buffer，避免使用低階 assembly 操作。

攻擊範例說明：
攻擊者嘗試傳入超長陣列將因 require 檢查而失敗，進而保護了合約狀態。
*/

contract FixedContract {
    // 狀態變數：固定大小的 buffer，長度為 1
    bytes32[1] public buffer;
    // 狀態變數：owner
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // 修正重點：檢查輸入陣列長度，確保不超過 buffer 長度
    function writeData(bytes32[] calldata _data) external {
        require(_data.length <= buffer.length, "Input length too long");
        // 安全寫入：僅更新 buffer 內部的項目
        for (uint256 i = 0; i < _data.length; i++) {
            buffer[i] = _data[i];
        }
    }
}

/*
攻擊合約範例（攻擊將失敗）：
由於修正後的合約在 writeData 函式中加入了輸入長度檢查，
攻擊者如果試圖傳入長度為 2 的陣列將會觸發 require 檢查，導致交易 revert，
從而防止了 buffer overflow 攻擊。
*/

contract AttackFixed {
    FixedContract public fixedContract;

    constructor(address _fixedContractAddress) {
        fixedContract = FixedContract(_fixedContractAddress);
    }

    function attack() public {
        // 嘗試傳入一個包含 2 個元素的陣列，此操作將因 require 檢查而失敗
        bytes32[] memory maliciousData = new bytes32[](2);
        maliciousData[0] = bytes32(uint256(0));
        maliciousData[1] = bytes32(uint256(uint160(msg.sender)));

        // 此呼叫會 revert: "Input length too long"
        fixedContract.writeData(maliciousData);
    }
}
