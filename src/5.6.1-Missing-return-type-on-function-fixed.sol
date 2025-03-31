pragma solidity >=0.8.0;

// 正確定義接口 Token，要求 transfer() 回傳 bool
interface Token {
    function transfer() external returns (bool);
}

// 修正後的合約 GoodToken 正確實作了 Token 接口：
contract GoodToken is Token {
    // 修正重點：transfer() 正確回傳 bool，符合接口定義
    function transfer() external override returns (bool) {
        // 可放入真實的轉帳邏輯，本例僅回傳 true 表示成功
        return true;
    }
}

// Wallet 合約依賴正確實作的 Token 介面
contract Wallet {
    // 呼叫 Token.transfer() 並正確處理返回值
    function transfer(address token) external {
        require(Token(token).transfer(), "Transfer failed");
    }
}

/*
補充描述：
修正後，GoodToken 合約依據接口要求正確實作了 transfer() 並回傳 bool 值，
確保 Wallet 合約呼叫 transfer() 時能正確取得回傳結果，
避免了因缺乏返回值而可能引起的錯誤調用或錯誤的數據類型問題。

測試步驟說明：
1. 部署 GoodToken 合約。
2. 部署 Wallet 合約。
3. 呼叫 Wallet.transfer()，並傳入 GoodToken 合約的地址，
   這樣 Wallet.transfer() 內部呼叫 Token(token).transfer() 就會收到正確的 true 回傳值，
   而 require 條件得以正常通過。
*/