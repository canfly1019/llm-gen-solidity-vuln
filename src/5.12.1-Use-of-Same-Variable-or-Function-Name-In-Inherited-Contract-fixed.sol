pragma solidity >=0.8.0;

// 修正說明：
// 將 Presale 合約中誤用的局部變數移除，
// 並在建構子中正確地更新父合約的 state 變數 hardcap，
// 使得呼叫 fetchCap() 時回傳正確的 1000 ether。

contract Tokensale {
    // 將 hardcap 宣告為 public，初始值為 10000 ether
    uint public hardcap = 10000 ether;

    // 建構子
    constructor() {}

    // 回傳目前的 hardcap
    function fetchCap() public view returns(uint) {
        return hardcap;
    }
}

contract Presale is Tokensale {
    // 修正方式：避免在建構子中宣告局部變數 hardcap，
    // 而是直接對繼承而來的 state 變數 hardcap 賦值更新
    constructor() Tokensale() {
        hardcap = 1000 ether;  // 正確更新父合約 hardcap 的值
    }
}

// 測試合約用以展示修正後的行為
contract AttackFixed {
    // 測試流程：
    // 1. 部署 Presale 合約，此時 hardcap 會在建構子中被正確更新為 1000 ether。
    // 2. 呼叫 fetchCap()，應正確回傳 1000 ether。
    function attack(address presaleAddress) public view returns (uint) {
        return Presale(presaleAddress).fetchCap();
    }
}

/*
測試步驟說明：
1. 部署 Presale 合約，建構子會將父合約中 hardcap 的值更新為 1000 ether。
2. 使用 AttackFixed 合約呼叫 attack() 函式，回傳值應為 1000 ether，符合預期。
*/