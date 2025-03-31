pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Include the contracts under test
// Assuming the contracts are in the same directory or proper import paths

// The FixedRelayer contract
contract FixedRelayer {
    uint public transactionId;  // 狀態變數
    
    struct Tx {
        bytes data;
        bool executed;
    }
    
    mapping(uint => Tx) public transactions;
    
    // 修正後的 relay 函式，要求呼叫方提供足夠 gasLimit
    function relay(address target, bytes memory _data, uint _gasLimit) public returns (bool) {
        // 防止重放攻擊
        require(!transactions[transactionId].executed, "Same transaction twice");
        transactions[transactionId].data = _data;
        transactions[transactionId].executed = true;
        transactionId += 1;
        
        // 使用 call 並明確傳遞 gas 限制
        (bool success, ) = target.call{gas: _gasLimit}(abi.encodeWithSignature("execute(bytes,uint256)", _data, _gasLimit));
        return success;
    }
}

// FixedTarget contract with remaining gas check
contract FixedTarget {
    // 注意: heavy computation 模擬以 for-loop
    function execute(bytes memory _data, uint _gasLimit) public {
        require(gasleft() >= _gasLimit, "not enough gas");
        
        // 模擬消耗大量 gas 的運算
        uint sum = 0;
        // 這個 loop 模擬了 heavy computation
        for (uint i = 0; i < 100000; i++) {
            sum += i;
        }
        // 後續執行其他合約邏輯，可以透過 _data 處理其他資訊
    }
}

// FixedAttack contract attempts to utilize the relay
contract FixedAttack {
    FixedRelayer public relayer;
    FixedTarget public target;
    
    // constructor 必須提供 FixedRelayer 與 FixedTarget 的地址
    constructor(address _relayer, address _target) {
        relayer = FixedRelayer(_relayer);
        target = FixedTarget(_target);
    }
    
    // 攻擊方法: 就算攻擊者試圖發起攻擊，只有提供足夠 gasLimit 才能完成 execute，否則就會 revert
    function attack() public {
        bytes memory data = "";
        // 此處攻擊者傳入 300000，若不足夠則會 revert
        uint gasLimit = 300000;
        relayer.relay(address(target), data, gasLimit);
    }
}

// 測試合約
contract FixedGasTest is Test {
    FixedRelayer relayer;
    FixedTarget target;
    FixedAttack attack;

    function setUp() public {
        relayer = new FixedRelayer();
        target = new FixedTarget();
        attack = new FixedAttack(address(relayer), address(target));
    }

    // 測試：提供不足的 gasLimit 時，relay call 會回傳 false，但交易記錄仍應被標記為 executed
    function testInsufficientGasRelay() public {
        bytes memory data = "";
        uint insufficientGas = 10000; // 明顯不足的 gas
        bool success = relayer.relay(address(target), data, insufficientGas);
        // 呼叫失敗，因為 execute 裡的 require 檢查未通過
        assertTrue(!success, "Relay call should fail with insufficient gas");

        (bytes memory txData, bool executed) = relayer.transactions(0);
        assertTrue(executed, "Transaction record should be marked as executed even if call failed");
    }

    // 測試：攻擊者利用 FixedAttack 呼叫 relay，交易記錄應被正確更新
    function testAttack() public {
        // 不論是否攻擊成功 (execute 失敗預期)，transactionId 都會遞增
        attack.attack();
        uint txId = relayer.transactionId();
        assertEq(txId, 1, "TransactionId should be incremented after attack");
    }

    // 測試：當提供足夠的 gasLimit 時，目標合約的 execute 函式得以順利執行
    // 注意：由於 execute 中消耗大量 gas，因此必須提供一個非常充足的 gasLimit
    function testSuccessfulRelay() public {
        bytes memory data = "";
        // 這裡提供一個極高的 gasLimit，確保在進入 FixedTarget.execute 時，剩餘 gas 足以通過 require()
        uint sufficientGas = 10_000_000;
        bool success = relayer.relay(address(target), data, sufficientGas);
        assertTrue(success, "Relay call should succeed with sufficient gas");
    }
}
