pragma solidity >=0.8.0;

// 修正後的程式碼：利用 safe math 的檢查防止 underflow 漏洞
// 此版本在進行減法時，先檢查是否會 underflow，若會則 revert

contract FixedMappingSym1 {
    // 狀態變數：同樣使用 mapping 儲存 key 對應的數值
    mapping(uint256 => uint256) public map;

    // 修正後的函式：使用 sub 函式進行安全相減
    function init(uint256 k, uint256 v) public {
        map[k] = sub(map[k], v);
    }

    // SafeMath 版本的 sub 函式，避免 underflow
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "Subtraction underflow");
        return a - b;
    }
}

// 攻擊示範：試圖觸發 underflow，但因為安全檢查而無法成功
contract AttackFixed {
    // 注意：由於 fixed 是 Solidity 的保留字，因此此處採用 fixedContract 作為變數名稱
    FixedMappingSym1 public fixedContract;

    // 部署前先部署 FixedMappingSym1，並將其地址傳入
    constructor(address _fixedAddress) {
        fixedContract = FixedMappingSym1(_fixedAddress);
    }

    // 嘗試攻擊：對預設值為 0 的 map[key] 減 1，預期此操作會因 require 檢查失敗而 revert
    function tryAttack(uint256 key) public returns (bool) {
        // 使用 try/catch 來捕捉 revert，若 underflow 被阻止，則回傳 false
        try fixedContract.init(key, 1) {
            // 若無 revert (不應發生)，則返回 true
            return true;
        } catch {
            // revert 成功，表示漏洞已被修正
            return false;
        }
    }
}

// 部署與測試步驟：
// 1. 部署 FixedMappingSym1 合約
// 2. 部署 AttackFixed 並傳入 FixedMappingSym1 的地址
// 3. 呼叫 AttackFixed.tryAttack(key) 來確認 underflow 攻擊無法執行，該函式應回傳 false
