pragma solidity >=0.8.0;
// SPDX-License-Identifier: UNLICENSED

// 修正後合約：移除冗餘的 fallback()，僅保留正確用來接收 Ether 的 receive() 
// 修正說明：移除 fallback() 以避免因誤用非空 calldata 的轉帳而導致交易 revert。

contract ExRedundantFixed {
    // 正確使用 receive() 來僅處理空 calldata 的情形
    receive() external payable {
        // 正常接收 Ether，不進行其他處理
    }
    
    // 儲存累計接收的 Ether 金額
    uint256 public totalReceived;
    
    // 存款函數
    function deposit() external payable {
        totalReceived += msg.value;
    }
    
    // 每個地址的存款記錄
    mapping(address => uint256) public balances;
    
    function depositFor() external payable {
        balances[msg.sender] += msg.value;
        totalReceived += msg.value;
    }
}

// 攻擊合約：嘗試利用非空 calldata 發送 Ether，但因合約已移除 fallback()，因此會 revert
// 攻擊流程說明：傳送非空 calldata 無法匹配任何函數選擇子，使交易 revert，從而無法進行攻擊。

contract AttackFixed {
    // 注意：ExRedundantFixed 仍擁有接收 payable 的能力，所以構造子參數須為 payable address
    ExRedundantFixed public fixedContract;
    
    // 修改後：使用 payable address 接收已修正合約地址
    constructor(address payable _fixedAddress) {
        fixedContract = ExRedundantFixed(_fixedAddress);
    }
    
    // 攻擊示例：嘗試發送帶有非空 calldata 的轉帳
    function attack() external payable {
        // 由於合約中不再有 fallback()，帶有非空 calldata 的 call 會找不到对应函數而 revert
        (bool success, ) = address(fixedContract).call{value: msg.value}(abi.encodePacked("attack"));
        require(success, "Attack failed: no fallback exists in fixed contract");
    }
    
    // 正常 deposit 使用：明確呼叫 depositFor() 函數進行操作
    function normalDeposit() external payable {
        fixedContract.depositFor{value: msg.value}();
    }
}

/*
部署及測試流程（繁體中文）：
1. 部署 ExRedundantFixed 合約，此合約已移除冗餘 fallback()。
2. 部署 AttackFixed 合約，建構子中傳入 ExRedundantFixed 的 payable 地址。
3. 攻擊者呼叫 AttackFixed 的 attack() 函數，附帶 Ether 與非空 calldata，
   因為不存在 fallback()，使得此類轉帳找不到入口而 revert，從而無法成功攻擊。
4. 使用者可透過 normalDeposit() 或 depositFor() 明確存款，確保正常運作。
*/