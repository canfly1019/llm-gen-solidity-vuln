pragma solidity >=0.8.0;

/*
    修正說明：
    為了防止 Improper Input Validation 漏洞，此修正版在 transfer 函數中加入了 onlyPayloadSize 修飾子，
    用以檢查 msg.data 的長度是否正確（預期為 2 個 32 位元參數資料，加上 4 位元組的 function selector）。
    攻擊者若試圖利用 Short Address Attack，會因為資料長度不符而導致交易失敗。
*/

contract NonPayloadAttackableTokenFixed {
    mapping(address => uint256) public balances;

    // 建構子，設定發行者初始餘額
    constructor() {
        balances[msg.sender] = 1000;
    }

    // onlyPayloadSize 修飾子：確保傳入資料長度正確
    modifier onlyPayloadSize(uint size) {
        // 注意：msg.data 的前 4 個位元組為函數選擇子，其餘為參數數據
        require(msg.data.length == size + 4, "Invalid payload size");
        _;
    }

    // 修正後的 transfer 函式，加入了 onlyPayloadSize 修飾子
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        // 執行轉帳操作
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
}


/*
    測試攻擊合約：
    該攻擊合約試圖利用短位元組資料攻擊 NonPayloadAttackableTokenFixed 合約，但由於已加入 payload size 檢查，
    攻擊嘗試將會因為資料長度不正確而觸發錯誤，從而避免不正確的參數解析與潛在資金被挪用。
*/

contract AttackFixed {
    NonPayloadAttackableTokenFixed public target;

    // 建構子設定目標合約
    constructor(address _target) {
        target = NonPayloadAttackableTokenFixed(_target);
    }

    // 攻擊函數，傳入的 shortData 資料長度若不足，交易會失敗
    function attack(bytes calldata shortData) public {
        (bool success, ) = address(target).call(shortData);
        require(success, "Attack failed as expected due to payload size check");
    }
}
