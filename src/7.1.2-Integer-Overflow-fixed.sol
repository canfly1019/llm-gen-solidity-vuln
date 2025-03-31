pragma solidity >=0.8.0;

// 修正後程式碼：採用 SafeMath 類似的加法檢查，避免整數溢位問題

contract IntegerOverflowMappingSym1Fixed {
    mapping(uint256 => uint256) public map;

    // 修正函式：init 使用安全加法函式 add 來避免溢位
    function init(uint256 k, uint256 v) public {
        // 這邊直接呼叫自訂的 add 函式，該函式會檢查 overflow
        map[k] = add(map[k], v);
    }

    // 安全加法函式，模仿 SafeMath.add 的實作
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

// 修正攻擊範例說明：
// 在修正後的合約中，因為 init 函式中使用了 add 函式進行 overflow 檢查，
// 若傳入的參數會導致溢位，require 條件不成立，交易將 revert，從而有效防止攻擊者利用溢位更改狀態。
// 攻擊者無法再利用類似 overflow 的方式操控 map 的數值。