// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
修正描述：
  為了避免因使用過時的建構子宣告方式而導致漏洞，本修正版本中採用了正確的 constructor 關鍵字，
  使合約初始化只能在部署時執行一次，並且不會暴露任何可被攻擊者後續呼叫的公開初始化函式。

修正步驟：
  1. 使用 constructor 正確定義建構子，在部署時初始化狀態變數 x 為 1。
  2. 刪除原本易受攻擊的初始化公用函式，攻擊者將無法再利用初始化漏洞修改合約狀態。
*/

contract OutdatedCompilerVersion {
    // 狀態變數 x 正確在建構子中初始化
    uint public x;
    
    // 正確使用 constructor 定義建構子，只於部署時執行一次
    constructor() {
        x = 1;
    }
}

// 嘗試模擬攻擊的合約，但由於目標合約已正確實作，沒有可被反覆呼叫的初始化函式，
// 因此攻擊合約的攻擊行為將無法成功
contract AttackFixed {
    function attack(address _vulnerableAddress) public {
        // 試圖呼叫一個不存在的初始化函式 (原漏洞函式已被移除)，此呼叫將會失敗
        // OutdatedCompilerVersion vulnerable = OutdatedCompilerVersion(_vulnerableAddress);
        // vulnerable.OutdatedCompilerVersion_(); // 此函式不存在
    }
}
