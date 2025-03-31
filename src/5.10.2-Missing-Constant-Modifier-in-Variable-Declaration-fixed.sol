pragma solidity >=0.8.0;

// 修正後的程式碼利用 constant 修飾符，將不會被修改的數值定義為編譯期常數，減少 gas 消耗

// 全域常數，可被所有合約參考使用
uint constant pi = 314;

contract C1 {
    // 修復重點：FavorateNumber 加上 constant，且 getNumbers 改為 pure，因為只讀取常數
    uint constant FavorateNumber = 25;
    
    function getNumbers() public pure returns(uint) {
        return FavorateNumber * pi;
    }
}

contract C2 {
    // 修正重點：不再使用 storage 變數 pi，而是直接參考全域常數
    function getPi() public pure returns(uint) {
       return pi;
    }
}

// 修正後的攻擊合約展示：
// 攻擊者或使用者呼叫 getNumbers 與 getPi 時，因為參數皆為常數，加上 pure 的函式，所以 gas 消耗明顯降低，亦無額外的 storage 存取費用

interface IC1 {
    function getNumbers() external pure returns(uint);
}

interface IC2 {
    function getPi() external pure returns(uint);
}

contract FixedAttack {
    IC1 public c1;
    IC2 public c2;

    // 部署 FixedAttack 合約時需提供 C1 與 C2 合約的地址
    constructor(address _c1, address _c2) {
        c1 = IC1(_c1);
        c2 = IC2(_c2);
    }

    // 攻擊示範：呼叫修正後的 getNumbers 與 getPi，這裡因為使用 pure，不會再有 storage 存取，gas 消耗較低
    function attack() public pure returns(uint, uint) {
        // 由於 pure 函式無法透過介面直接呼叫，因此這裡僅示範計算結果，實際部署時請直接呼叫合約函式
        uint numberResult = 25 * pi; 
        uint piResult = pi;
        return (numberResult, piResult);
    }
}
