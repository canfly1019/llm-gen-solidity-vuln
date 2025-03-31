pragma solidity >=0.8.0;

/*
  修正說明：
  使用正確的 constructor() 來設置 owner，確保此函式
  只會在部署時呼叫一次，從而避免任何人可以重設 owner 的漏洞。

  攻擊手法說明：
  攻擊者試圖呼叫其他函式來重設 owner，將失敗，因為 constructor 僅在部署時自動執行一次。
*/

contract FixedVersionIssue {
    // 狀態變數 (安全重點部位): owner
    address public owner;

    // 正確的建構子，只於部署時呼叫一次
    constructor() {
        owner = msg.sender;
    }

    // 限制權限函式，只有 owner 可以存取
    function restrictedAction() public view returns (string memory) {
        require(msg.sender == owner, "Only owner allowed");
        return "You have accessed restricted data!";
    }
}

// 攻擊合約示範：在修正後的合約中，不存在可被攻擊者任意呼叫以重設 owner 的函式，
// 因此攻擊嘗試將失敗。
contract FixedAttack {
    FixedVersionIssue public fixedContract;

    // 部署時指定 FixedVersionIssue 合約地址
    constructor(address _fixedAddress) {
        fixedContract = FixedVersionIssue(_fixedAddress);
    }

    // 攻擊函式嘗試存取 restrictedAction，但由於 owner 僅在部署時設定，
    // 故攻擊者通常無法通過權限檢查
    function attack() public view returns (string memory) {
        return fixedContract.restrictedAction();
    }
}
