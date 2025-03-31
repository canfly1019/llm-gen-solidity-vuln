// Solidity版本標示：請使用 Solidity >=0.8.0
pragma solidity >=0.8.0;

// FixedContract 已修正 Improper Type Usage 漏洞，正確使用 address 型態儲存 owner

contract FixedContract {
    // 狀態變數正確地宣告為 address
    address public owner;

    constructor() {
        owner = msg.sender; // 正確賦值，不進行不必要的型態轉換
    }

    // 僅限 owner 執行的功能，直接利用 address 型態來做檢查
    function restrictedAction() public view returns (string memory) {
        require(msg.sender == owner, "Not owner");
        return "Action performed";
    }
}

// 呼叫方示例合約：
// 攻擊手法說明（繁體中文）：
// 在修正後的程式碼中，透過正確使用 address 型態，比較能確保只有真正的 owner
// 能夠呼叫 restrictedAction()。因此攻擊者無法藉由型態轉換或型別混淆來冒充 owner 身份。

contract SafeCaller {
    // 將變數名稱從 fixed 改為 fixedContract 以避免與保留字衝突
    FixedContract public fixedContract;

    constructor(FixedContract _fixedContract) {
        fixedContract = _fixedContract;
    }

    function callRestrictedAction() public view returns (string memory) {
        // 只有當呼叫者確實為 owner 時，才呼叫 restrictedAction()
        require(msg.sender == fixedContract.owner(), "Not owner");
        return fixedContract.restrictedAction();
    }
}
