pragma solidity >=0.8.0;

// Fixed Code: 移除硬編碼固定 gas 值，讓呼叫自動轉發剩餘的 gas 數量

interface ICallable {
    function callMe() external;
}

// HardcodedGood 合約修正了固定 gas 數量的問題，確保在 EVM gas 成本變化時仍能正常運作
contract HardcodedGood {
    address payable public _callable;
    ICallable public callable;  

    // 建構子，傳入目標合約地址（例如攻擊合約或其他合約地址），以利後續呼叫
    constructor(address payable _target) payable {
        _callable = _target;  
        callable = ICallable(_target);
    }
    
    function doTransfer(uint256 amount) public {
        // 注意：transfer 仍然固定轉發 2300 gas，若目標合約複雜可能仍會出問題
        _callable.transfer(amount);
    }
    
    function doSend(uint256 amount) public returns (bool) {
        bool success = _callable.send(amount);
        return success;
    }
    
    // 修正後不再硬編碼 gas 限制，預設轉發所有剩餘 gas
    function callLowLevel() public {
        (bool success, ) = _callable.call{value: 0}("");
        require(success, "callLowLevel failed");
    }
    
    // 呼叫目標合約的 callMe 函數，不再固定 gas，讓目標合約自主決定 gas 消耗
    function callWithArgs() public {
        callable.callMe();
    }
}

/*
修正說明 (繁體中文)：
1. 將 callLowLevel 中的硬編碼 gas 限制移除，改為使用默認轉發全部剩餘 gas，避免未來 EVM gas 指令成本調整後導致呼叫失敗。
2. 對於 callWithArgs，直接呼叫目標合約的 callMe() 函數，不強制限制 gas 量，確保合約可在各種情況下正確運行。
3. 雖然 transfer 和 send 固定 2300 gas 問題仍存在，但此修正主要針對 hardcoded gas call 的漏洞。
*/