pragma solidity >=0.8.0;

// 修正後的合約
// 修正重點: 移除部署時就固定的 block.timestamp 變數，改為在每次函式呼叫時利用當前區塊的 timestamp，
//          以減少礦工藉由操控 timestamp 的可能性。注意：雖然這仍然有一定的操控空間，但至少不再依賴於一個固定值。

contract TestFixed {
    // 不再於狀態變數中儲存固定時間，改為在 pay() 函式中動態取得當前區塊的 timestamp
    function pay() public payable {
        uint currentTime = block.timestamp;  // 使用當前區塊時間
        if (currentTime % 2 == 1) {
            // 使用 transfer 進行 Ether 傳送（實務上請加入錯誤處理機制）
            payable(msg.sender).transfer(100);
        }
    }
}

// 雖然修正後的合約仍然根據區塊時間運作，但因每次都以當前時間作判斷，攻擊者和礦工難以預先設定有利條件。
// 攻擊合約示例：
// 1. 部署 TestFixed 合約；
// 2. 攻擊者部署 AttackFixed 合約，傳入 TestFixed 的位址；
// 3. 攻擊者呼叫 attack()，但因為 block.timestamp 為動態值，攻擊者較難預知條件是否滿足。

contract AttackFixed {
    TestFixed public target;

    constructor(address _target) {
        target = TestFixed(_target);
    }

    function attack() public payable {
        target.pay{value: msg.value}();
    }

    receive() external payable {}
}
