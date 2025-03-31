// Solidity version >=0.8.0
pragma solidity >=0.8.0;

/*
  修正說明:
  在修正的程式碼中，modifier onlyOwner 正確地檢查 msg.sender 是否等於預先設定的 owner，確保只有合約擁有者能執行受保護的函式。
  即使攻擊者試圖呼叫 withdraw()，只要他不是初始設定的 owner，就會因為 require 條件失敗而無法提取合約內的 ether。

  測試步驟:
  1. 部署 FixedContract，部署者將成為 owner。
  2. 向合約存入一定數量的 ether。
  3. 只有 owner 呼叫 withdraw() 才能成功提取 ether；非 owner 呼叫 withdraw() 將會失敗。
*/

contract FixedContract {
    address public owner;

    // 正確的 modifier：檢查 msg.sender 是否與設定的 owner 相同
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // 敏感操作：僅允許 owner 來提取合約中所有的 ether
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // 接收 Ether 的函式
    receive() external payable {}
}

// 測試用攻擊合約：如果攻擊合約嘗試呼叫 withdraw()，由於只有 owner 能成功，因此呼叫將會失敗，從而保障資金安全。
contract AttackFixed {
    FixedContract public fixedContract;

    // 修改參數型態為 address payable 以解決潛在的編譯錯誤
    constructor(address payable _fixedContractAddress) {
        fixedContract = FixedContract(_fixedContractAddress);
    }

    // 攻擊步驟：試圖呼叫 withdraw()，但由於只有 owner 能執行，呼叫將會 revert
    function attack() public {
        fixedContract.withdraw();
    }

    // 接收來自 FixedContract 的轉帳
    receive() external payable {}
}
