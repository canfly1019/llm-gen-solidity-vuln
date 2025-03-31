pragma solidity >=0.8.0;

// 修正後的合約，修復 Wrong Function Modifier 漏洞
// 修正重點：將僅供外部呼叫的函式修正為 external modifier，可節省 gas 並避免無謂的內部呼叫
contract C {
    // 狀態變數 x
    bytes public x = "012345678901234567890123456789";

    // 修正：使用 external 修飾符，僅限外部呼叫，內部呼叫則不被允許
    function test() external returns (uint) {
        // 以下兩行模擬資料修改操作
        x.push() = 0x01; // 修正後的操作，僅在外部呼叫時執行
        x.push() = 0x02;
        return x.length;
    }
}

// 呼叫合約：用以測試修正後的 C 合約
// 說明：此合約模擬一個正常的外部合約呼叫流程，呼叫 test() 並取得結果
contract Caller {
    C public target;

    // 部署 Caller 合約時，必須指定已部署之 C 合約地址
    constructor(address _target) {
        target = C(_target);
    }

    // 呼叫修正後的 test() 函式
    function callTest() public returns (uint) {
        uint len = target.test();
        return len;
    }
}

/*
部署與測試步驟說明：
1. 部署修正後的合約 C 至區塊鏈上。
2. 使用 C 合約的地址部署 Caller 合約。
3. 呼叫 Caller 合約中的 callTest() 函式，進而觸發 C 合約中的 test()，
   因 test() 已標示為 external，呼叫將使用 calldata，避免了不必要的 gas 消耗。
*/