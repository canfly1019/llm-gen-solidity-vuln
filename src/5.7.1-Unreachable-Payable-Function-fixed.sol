pragma solidity >=0.8.0;

// SPDX-License-Identifier: UNLICENSED
/*
修正版本說明：
原始漏洞是允許合約接受 Ether，但沒有提款機制，導致乙太幣一旦進入合約便無法取出，造成資金永久鎖定。
本修正版本的目標是完全拒絕接收 Ether，因此移除原本使用 payable 的 receive 函數，並改用非 payable 的 fallback 函數來反彈所有傳入 Ether 的呼叫。
這樣，即使 Ether 被送入合約，交易也會直接 revert，無法在合約中累積任何資金。
*/

contract LockedFixed {
    // 修正重點：移除 payable 的 receive 函數，改用非 payable 的 fallback 函數，確保任何試圖傳送 Ether 的呼叫都會 revert。
    fallback() external {
        revert("This contract does not accept Ether");
    }
}

// 攻擊或測試合約：試圖將 Ether 傳入 LockedFixed 合約，以確認修正是否生效。
contract AttackLockedFixed {
    // 試圖將 Ether 傳送到 LockedFixed 合約中，但由於修正不接受 Ether，交易應會 revert。
    function attack(address payable target) external payable returns (bool) {
        // 嘗試傳送 Ether 至 target，預期此呼叫會因為非 payable 而失敗。
        (bool sent, ) = target.call{value: msg.value}("");
        return sent; // 回傳 false 表示失敗。
    }

    // 查詢目標合約餘額，用以驗證合約中沒有任何 Ether 累積
    function getTargetBalance(address payable target) external view returns (uint) {
        return target.balance;
    }
}

/*
測試步驟說明：
1. 部署 LockedFixed 合約。
2. 部署 AttackLockedFixed 合約。
3. 從 AttackLockedFixed 呼叫 attack 函數，並傳送一定數量的 Ether 給 LockedFixed，預期該呼叫會 revert或返回 false。
4. 利用 getTargetBalance 函數確認 LockedFixed 合約中沒有任何 Ether 累積。
*/