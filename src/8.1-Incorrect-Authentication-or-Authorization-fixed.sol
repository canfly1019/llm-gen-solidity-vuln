pragma solidity >=0.8.0;

/*
  修正後版本：FixedAuth
  說明：在每個敏感操作函式中加入 require 檢查，僅允許管理員呼叫，從而避免未經授權的訪問。

  測試方法：
  1. 部署 FixedAuth 合約，初始管理員設定為部署者。
  2. 若攻擊者嘗試透過呼叫 changeAdmin 或 privilegedAction 進行未授權操作，
     合約會 revert，確保只有管理員能夠執行這些操作。
*/

contract FixedAuth {
    // 狀態變數：管理員
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    // 安全函式：僅允許管理員呼叫，可變更管理員
    function changeAdmin(address _newAdmin) public {
        require(msg.sender == admin, "Not admin"); // 修正處：驗證呼叫者是否為管理員
        admin = _newAdmin;
    }

    // 安全函式：僅允許管理員呼叫執行特權操作
    function privilegedAction() public view returns (string memory) {
        require(msg.sender == admin, "Not admin"); // 修正處：驗證呼叫者是否為管理員
        return "Privileged action executed";
    }

    // 正確定義接收 Ether 的 fallback 函式
    receive() external payable {}
}

// 攻擊測試合約，但在修正後的版本中攻擊將會失敗
contract AttackFixed {
    FixedAuth public fixedContract;

    constructor(FixedAuth _fixed) {
        fixedContract = _fixed;
    }

    // 嘗試利用漏洞進行攻擊，但由於已加入身份驗證，將 revert 並使攻擊失敗
    function attack() public returns (bool) {
        try fixedContract.changeAdmin(msg.sender) {
            // 若能成功呼叫則表示攻擊成功（但預期不會發生）
            return true;
        } catch {
            // 如預期般測試失敗，即顯示防禦成功
            return false;
        }
    }
}
