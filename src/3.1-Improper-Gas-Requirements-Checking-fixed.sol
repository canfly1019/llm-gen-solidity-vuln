// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
  修正後的版本：Improper Gas Requirements Checking
  描述: 修正方法在於讓呼叫方在 relay 函式中明確傳入執行目標合約所需的 gasLimit
        並在 Target 合約的 execute 函式內加入剩餘 gas 檢查，確保執行環境具備足夠的 gas
        以正確完成 heavy computation，而不會因為 gas 不足而意外失敗。
*/

// 修正後的 Relayer 合約，新增 gasLimit 參數以便使用者指定呼叫 execute 時所提供的 gas
contract FixedRelayer {
    uint public transactionId;  // 狀態變數
    
    struct Tx {
        bytes data;
        bool executed;
    }
    
    mapping(uint => Tx) public transactions;
    
    // 修正點：在 relay 函式中加入 _gasLimit 參數，且使用 call 時指定 gas 限制
    function relay(address target, bytes memory _data, uint _gasLimit) public returns (bool) {
        // 防止重放攻擊
        require(!transactions[transactionId].executed, "Same transaction twice");
        transactions[transactionId].data = _data;
        transactions[transactionId].executed = true;
        transactionId += 1;
        
        // 使用 call 時指定 gas 限制，並且在 encode 中傳入 _gasLimit 給目標合約
        (bool success, ) = target.call{gas: _gasLimit}(abi.encodeWithSignature("execute(bytes,uint256)", _data, _gasLimit));
        return success;
    }
}

// 修正後的 Target 合約，增加對剩餘 gas 的檢查，以保證足夠資源進行 heavy computation
contract FixedTarget {
    // 修正點：增加 _gasLimit 參數，並使用 require 檢查剩餘 gas 是否達到需求
    function execute(bytes memory _data, uint _gasLimit) public {
        require(gasleft() >= _gasLimit, "not enough gas");
        
        // 模擬消耗大量 gas 的運算
        uint sum = 0;
        for (uint i = 0; i < 100000; i++) {
            sum += i;
        }
        // 後續執行其他合約邏輯
    }
}

// 攻擊合約 FixedAttack：在修正後版本中，由於已正確管理 gas，攻擊者將無法透過提供不足 gasLimit 的方式輕易觸發漏洞
contract FixedAttack {
    FixedRelayer public relayer;
    FixedTarget public target;
    
    // 部署時必須提供 FixedRelayer 與 FixedTarget 的地址
    constructor(address _relayer, address _target) {
        relayer = FixedRelayer(_relayer);
        target = FixedTarget(_target);
    }
    
    // 即便攻擊者試圖發起攻擊，因為 require(gasleft() >= _gasLimit) 的檢查將會避免
    // 只有在提供正確且足夠的 gasLimit 時，目標函式才能順利執行
    function attack() public {
        bytes memory data = "";
        uint gasLimit = 300000; // 指定足夠的 gas，避免觸發 require 失敗
        relayer.relay(address(target), data, gasLimit);
    }
}
