pragma solidity >=0.8.0;

// 修正後的合約，改善了外部呼叫的不確定性
// 採用 owner 身份驗證以僅允許可信的外部合約被設定，並使用 interface 來定義外部呼叫

contract FixedExternalCall {
    address public owner;
    address public externalContract; // 可信外部合約地址

    constructor() {
        owner = msg.sender;
    }

    // 僅允許擁有者設定可信外部合約地址，避免攻擊者隨意替換
    function setExternalContract(address _contract) public {
        require(msg.sender == owner, "Not owner");
        externalContract = _contract;
    }

    // 改用 interface 呼叫外部合約的函式，並強制要求 externalContract 必須被正確設置
    function executeExternalCall(string calldata command) public returns (bytes memory) {
        require(externalContract != address(0), "External contract not set");
        ExternalInterface ext = ExternalInterface(externalContract);
        bytes memory result = ext.executeCommand(command);
        return result;
    }

    // fallback function 用以接收 Ether
    receive() external payable {}
}

// 定義外部合約的 interface，要求其必須實現 executeCommand 方法
interface ExternalInterface {
    function executeCommand(string calldata command) external returns (bytes memory);
}

/* 攻擊防禦說明（繁體中文）：
   1. 在修正版本中，我們加入了 owner 身份驗證，只有合約擁有者可以設定外部呼叫的合約地址，
      因此攻擊者無法隨意替換為惡意合約。
   2. 使用 interface 呼叫外部合約，讓呼叫流程更加明確，避免低階 call 帶來的不確定性。
   3. 這樣的修正可以有效降低因非區塊鏈外部呼叫導致的結果不一致問題，確保所有節點執行一致的邏輯。
*/