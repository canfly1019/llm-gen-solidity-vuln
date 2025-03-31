// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// 介面定義，供外部呼叫使用
interface ICalled {
    function f() external;
}

// 修正後合約：FixedContract
// 修正重點：
// 將事件 emit 移至外部呼叫之前，確保狀態變更和記錄在進行外部呼叫前已確定，
// 從而避免攻擊者利用回調觸發重入攻擊所造成的非預期狀態。
contract FixedContract {
    uint public counter; // 狀態變數（修正重點）

    event Counter(uint counter);

    // 修正函式：
    // 先更新狀態並 emit 事件，再進行外部呼叫，確保狀態記錄完整
    function bug(ICalled d) public {
        counter += 1; // 狀態更新
        emit Counter(counter);
        // 外部呼叫在狀態更新和事件記錄後進行
        d.f();
    }
}

// 修正後攻擊者合約：AttackerFixed
// 注意：變數名稱從 fixed 變更為 fixedContract 以避免與 Solidity 關鍵字衝突
contract AttackerFixed is ICalled {
    FixedContract public fixedContract;
    uint public attackCount;

    // 在部署 AttackerFixed 時，提供 FixedContract 的地址
    constructor(address _fixedContract) {
        fixedContract = FixedContract(_fixedContract);
    }

    // 攻擊入口：呼叫 FixedContract.bug() 並傳入自身地址
    function attack() public {
        fixedContract.bug(this);
    }

    // 回調函式：即便嘗試重入，由於狀態與事件先行處理，
    // 攻擊者無法藉由重入造成額外狀態更動
    function f() external override {
        if (attackCount < 2) {
            attackCount++;
            fixedContract.bug(this);
        }
    }
}

/*
部署及測試步驟：
1. 部署 FixedContract。
2. 部署 AttackerFixed 並傳入 FixedContract 的地址（注意變數名稱 fixedContract 避免關鍵字衝突）。
3. 呼叫 AttackerFixed.attack()，觀察 counter 狀態變數的變化。

測試說明：
由於修正後的 bug() 函式先將狀態變更及事件記錄完成，再進行外部呼叫，
攻擊者即便嘗試利用回調進行重入，也無法影響已記錄的狀態，
從而有效地避免了因重入導致不預期狀態帶來的性能或可用性問題。
*/