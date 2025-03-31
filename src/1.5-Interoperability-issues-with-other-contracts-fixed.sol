// Fixed Code (修正後的版本)
// 說明：
// 修正後的程式碼將介面與實作正確對應，移除原本可能被誤認為是 view 的介面定義，
// 並在呼叫合約時明確使用正確的函式簽名。這樣做可以避免因誤用 call 方法而產生的互通性問題。

pragma solidity >=0.8.0;

// 修正後的合約，明確標示 myFunction 為可變動狀態的函式，不再使用 view 常數修飾
contract ConstantFixed {
    // 狀態變數：計數器
    uint public counter;

    // 此函式不再聲明為 view，正確反映其會修改狀態的特性
    function myFunction() public returns (uint) {
        counter++;
        return counter;
    }
}

// 修正後的合約，呼叫方式使用正確的字串參數進行 abi.encodeWithSignature 呼叫，
// 並在呼叫後加入對 success 的檢查，避免後續邏輯在呼叫失敗時繼續執行
contract NewContractFixed {
    function doSomething(address _addr) public returns (bool) {
        (bool success, ) = _addr.call(abi.encodeWithSignature("myFunction()"));
        require(success, "Call failed");
        return success;
    }
}

// 攻擊合約展示修正後合約的正當流程（此處僅作示範，由於修正後不存在漏洞，因此攻擊僅為測試呼叫效果）
contract TestAttackFixed {
    NewContractFixed public target;
    ConstantFixed public constantContract;

    // 部署時傳入 NewContractFixed 與 ConstantFixed 的位址
    constructor(address _target, address _constant) {
        target = NewContractFixed(_target);
        constantContract = ConstantFixed(_constant);
    }

    // 測試流程：呼叫 target 的 doSomething 方法後，檢查 constantContract.counter 是否正確增加
    function testCall() public returns (uint) {
        bool success = target.doSomething(address(constantContract));
        require(success, "Call to constantContract failed");
        return constantContract.counter();
    }
}

/*
測試流程：
1. 部署 ConstantFixed 合約，取得其位址。
2. 部署 NewContractFixed 合約，取得其位址。
3. 部署 TestAttackFixed 合約，傳入 NewContractFixed 與 ConstantFixed 的位址。
4. 呼叫 TestAttackFixed 合約的 testCall()，可觀察到 counter 正常遞增，且流程符合預期，不再受到舊介面誤導。
*/