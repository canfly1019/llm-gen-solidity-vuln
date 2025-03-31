// SPDX-License-Identifier: MIT
// 修正版本：Safe External Command Execution
// 此修正版本中，我們採用了白名單機制，以限制可執行的指令，
// 從而避免外部使用者藉由傳入危險指令導致不預期行為。

pragma solidity >=0.8.0;

contract SafeCommandExecutor {
    address public owner;
    // 白名單：只有被列入允許的指令才能被執行
    mapping(string => bool) public allowedCommands; // whitelist for commands

    event CommandAllowed(string command);
    event CommandRevoked(string command);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not allowed");
        _;
    }

    // 允許添加一個合法的指令到白名單
    function allowCommand(string calldata command) external onlyOwner {
        allowedCommands[command] = true;
        emit CommandAllowed(command);
    }

    // 從白名單中移除指令
    function revokeCommand(string calldata command) external onlyOwner {
        allowedCommands[command] = false;
        emit CommandRevoked(command);
    }

    // 安全執行指令
    // 此函數會先檢查待執行的指令是否存在於白名單中，若不允許則拒絕執行
    // 修正重點：移除了直接接收任意指令的風險
    function executeCommand(address target, string calldata command) external payable returns (bytes memory) {
        // 若指令不在白名單中，則拒絕執行，避免不安全行為
        require(allowedCommands[command], "Command not allowed");
        
        // 僅執行被允許的指令
        (bool success, bytes memory data) = target.call(abi.encodeWithSignature(string(abi.encodePacked(command, "()"))));
        require(success, "Command execution failed");
        return data;
    }
}

// 範例目標合約，在修正版本中建議僅允許執行特定安全函數
contract SafeTarget {
    // 此函數是預先定義的安全指令，僅允許被 SafeCommandExecutor 執行
    function doSomething() external pure returns (string memory) {
        return "Safe function executed";
    }
}

/*
部署與示範步驟：
1. 部署 SafeTarget 合約，該合約僅包含被認可的安全函數 doSomething()。
2. 部署 SafeCommandExecutor 合約。
3. 作為合約擁有者，呼叫 SafeCommandExecutor 的 allowCommand('doSomething')，將 'doSomething' 新增到白名單中。
4. 任何使用者皆可呼叫 executeCommand 並傳入 SafeTarget 的地址和 'doSomething' 指令，
   這樣只會執行白名單中的安全指令，避免攻擊者傳入危險指令。
*/
