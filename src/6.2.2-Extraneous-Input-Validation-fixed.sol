pragma solidity >=0.8.0;

// 修正後的程式碼：
// 修正方式一：改變 Foo 合約中的 require 條件，
//          使得符合業務邏輯的輸入可以被接受。在此案例中，我們改為要求 x 必須為正數。
// 修正方式二：也可以改變 Bar 合約傳入的參數，但這需要與業務邏輯匹配，
//          此處採用修正方式一以達到更普遍的正確性。

contract Foo {
    // 修正重點：更新 require 條件，改為檢查 x 是否大於 0，讓正常行為得以通過
    function baz(int256 x) public pure returns (int256) {
        require(x > 0, "x must be positive");
        return 42;
    }
}

contract Bar {
    Foo private f;

    constructor() {
        f = new Foo();
    }

    function doubleBaz() public view returns (int256) {
        // 修改傳入的參數，使其符合 Foo.baz 的要求
        return 2 * f.baz(1);
    }
}

// 最小可行的攻擊範例
// 在此情境下，呼叫 doubleBaz() 將成功，並回傳結果 84

contract AttackFixed {
    Bar public bar;

    event Result(int256 result);
    event Error(string message);

    constructor() {
        // 部署 Bar 合約前置作業
        bar = new Bar();
    }

    // 攻擊函式，用來呼叫修正後的合約函式 doubleBaz()
    function attack() public {
        try bar.doubleBaz() returns (int256 result) {
            // 成功執行，應回傳 84
            emit Result(result);
        } catch Error(string memory reason) {
            // 如果發生錯誤，回傳錯誤訊息
            emit Error(reason);
        } catch {
            emit Error("Unknown error");
        }
    }
}
