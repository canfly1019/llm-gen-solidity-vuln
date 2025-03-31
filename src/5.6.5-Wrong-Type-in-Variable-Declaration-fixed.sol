pragma solidity >=0.8.0;

// Fixed Code: 正確的資料型態宣告
// 修正後使用 bytes (一個連續位元資料) 來儲存資料，能夠有效減少不必要的記憶體浪費與 gas 消耗。

contract FixedSampleBytesArray {
    // 狀態變數使用正確的 bytes 型態，資料將以連續儲存的方式存在，避免每個元素額外預留記憶體空間。
    bytes public simBytes;

    // 函式：將傳入資料附加到 simBytes 中
    function appendSimBytes(bytes calldata _data) external {
        // 使用自定義 concat 函式來串接現有資料與新資料，避免使用不支援的 bytes.concat
        simBytes = _concat(simBytes, _data);
    }

    // internal 函式: 手動實作兩個 bytes 陣列的合併
    function _concat(bytes memory a, bytes calldata b) internal pure returns (bytes memory) {
        bytes memory result = new bytes(a.length + b.length);
        uint256 k = 0;
        // 複製 a 至 result
        for (uint256 i = 0; i < a.length; i++) {
            result[k++] = a[i];
        }
        // 複製 b 至 result
        for (uint256 i = 0; i < b.length; i++) {
            result[k++] = b[i];
        }
        return result;
    }

    /*
    修正範例說明：
    1. 使用連續的 bytes 儲存資料，使得每個新加入的資料不會額外浪費記憶體空間，從而使 gas 消耗大幅降低。
    2. 自定義的 _concat 函式完全取代了 bytes.concat，解決了編譯器在 Solidity 0.8.0 中找不到該函式的錯誤。
    */
}

// 攻擊合約範例
contract AttackFixed {
    FixedSampleBytesArray public fixedContract;

    // 部署時必須傳入 FixedSampleBytesArray 的合約地址
    constructor(address _fixed) {
        fixedContract = FixedSampleBytesArray(_fixed);
    }

    // 攻擊函式：以大量呼叫 appendSimBytes 來測試修正版本在 gas 使用上的改善
    function attack(uint256 count) external {
        for (uint256 i = 0; i < count; i++) {
            fixedContract.appendSimBytes(hex"00");
        }
    }

    /*
    說明：
    1. 此攻擊示例僅作為測試修正版本之 gas 效率的參考。
    2. 攻擊者雖然可以呼叫大量 appendSimBytes，但由於資料以更有效的格式儲存，gas 消耗明顯降低。
    */
}