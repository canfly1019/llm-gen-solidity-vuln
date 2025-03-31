// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
  修正說明:
  將映射中的資料型別從 uint32 改為 uint256，避免因轉型而造成截斷問題。
  即使攻擊者傳送超過 uint32 上限的 Ether，balance 仍能正確儲存完整的 msg.value 數值。

  測試步驟:
  1. 部署 FixedContract。
  2. 部署 AttackContractFixed，部署時傳入 FixedContract 的 payable address。
  3. 攻擊者透過 AttackContractFixed 呼叫 attack() 並傳送大於 uint32 上限的 Ether。
  4. 查詢餘額確認與實際傳入的 Ether 數目一致，證明漏洞已修正。
*/

contract FixedContract {
    // 修正：使用 uint256 儲存 Ether 數額，避免截斷問題
    mapping(address => uint256) public balance;

    // 正確使用 receive 函數來接受 Ether
    receive() external payable {
        // 直接將 msg.value (uint256) 記錄，不進行不必要的類型轉換
        balance[msg.sender] = msg.value;
    }

    // 查詢餘額函數
    function getBalance(address _addr) external view returns (uint256) {
        return balance[_addr];
    }
}

contract AttackContractFixed {
    // 注意：_fixedAddr 需為 payable address
    FixedContract public fixedContract;

    // 修改建構子的參數類型為 payable address
    constructor(address payable _fixedAddr) {
        fixedContract = FixedContract(_fixedAddr);
    }

    // 攻擊函數：傳送大於 uint32 上限的 Ether，但因為型別正確，餘額可正確紀錄
    function attack() external payable {
        require(msg.value > type(uint32).max, "\u8ACB\u50B3\u9001\u8D85\u904E uint32 \u6700\u5927\u503C\u7684 Ether");
        (bool success, ) = address(fixedContract).call{value: msg.value}("");
        require(success, "Call failed");
    }

    // 查詢正確的餘額
    function checkBalance() external view returns (uint256) {
        return fixedContract.getBalance(address(this));
    }
}
