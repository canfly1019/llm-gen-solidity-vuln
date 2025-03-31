// Fixed Code
// 修正後的程式碼：
// 1. 移除 extraneous field (balance) 以免導致與內部邏輯記錄重覆，
//    改用單一來源紀錄使用者餘額，即 mapping userBalance。
// 2. 若有需求查詢合約累積金額，可另外建立合約查詢邏輯，但不可讓外部隨意修改狀態。
// 3. 移除 setBalance 函式，避免攻擊者可以直接調整合約狀態。

pragma solidity >=0.8.0;

contract Fixed {
    // 僅採用單一來源記錄餘額：使用 mapping
    mapping(address => uint) internal userBalance;

    // 修正後的建構式，僅初始化使用 mapping
    constructor() payable {
        userBalance[msg.sender] = msg.value;
    }

    // withdraw 函式僅以 mapping 為查詢依據
    function withdraw(uint _amount) public {
        require(userBalance[msg.sender] >= _amount, "Insufficient funds");
        userBalance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    // 提供查詢使用者餘額的函式
    function getUserBalance(address _user) public view returns (uint) {
        return userBalance[_user];
    }
}

/*
修正後的狀態：
1. 合約內僅保有 userBalance 一個來源
2. 避免額外狀態變數可被外部未經授權修改，進而導致 node 之間狀態不同步或不一致
3. 修正後的設計提升了合約狀態的一致性與安全性。
*/