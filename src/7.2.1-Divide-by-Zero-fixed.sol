pragma solidity >=0.8.0;

// 修正後 SafeMath 程式碼，加入除以零的檢查
library SafeMath {
    // 修正重點: 在除法前檢查除數是否為 0，若為 0 則返回 0 避免錯誤
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) return 0; // 當除數為 0 時，直接返回 0，避免除法運算錯誤
        uint256 c = a / b;
        return c;
    }
}

// 測試合約，使用修正後的 SafeMath 庫
contract FixedDemo {
    using SafeMath for uint256;

    // 函式 tryDiv 測試不同狀況下的除法運算
    // 當 b 為 0 時，函式會返回 0，不再 revert
    function tryDiv(uint256 a, uint256 b) public pure returns (uint256) {
        return a.div(b);
    }

    /*
      測試步驟說明：
      1. 部署 FixedDemo 合約。
      2. 呼叫 tryDiv() 函式，可傳入任意的 a 與 b 值，包含 b 為 0 的情形。
      3. 當 b 為 0 時，函式會返回 0，避免觸發除以 0 而 revert 的問題，使合約運行更加穩定。
    */
}
