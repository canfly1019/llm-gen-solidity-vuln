/* SPDX-License-Identifier: UNLICENSED */
pragma solidity >=0.8.0;

// FixedWallet 合約已修正 Unsafe Credit Transfer 漏洞，透過先更新狀態，再進行 Ether 轉移以避免重入攻擊。
contract FixedWallet {
    // 儲存用戶餘額 (修正重點：先更新 userBalances，再進行 credit transfer)
    mapping(address => uint256) public userBalances;

    // 允許用戶充值 Ether
    function deposit() external payable {
        userBalances[msg.sender] += msg.value;
    }
    
    // 提款函式 (已修正重入漏洞)
    function withdrawBalance() public {
        uint256 amountToWithdraw = userBalances[msg.sender];
        require(amountToWithdraw > 0, "No balance to withdraw");
        
        // 修正漏洞：先更新狀態變數，再進行外部呼叫
        userBalances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Transfer failed");
    }

    // 定義 receive 與 fallback 以正確接收 Ether
    receive() external payable {}
    fallback() external payable {}
}

// 攻擊合約 (AttackFixed) 用於展示相同的攻擊方式在修正後的合約中將不再成功
contract AttackFixed {
    FixedWallet public fixedWallet;
    address public owner;
    uint256 public count;

    // 修改構造子參數型態為 address payable，避免類型轉換錯誤
    constructor(address payable _fixedWalletAddress) {
        fixedWallet = FixedWallet(_fixedWalletAddress);
        owner = msg.sender;
    }

    // 攻擊入口，先充值後嘗試提款
    function attack() external payable {
        require(msg.sender == owner, "Not owner");
        fixedWallet.deposit{value: msg.value}();
        fixedWallet.withdrawBalance();
    }

    // fallback 函式：在提款時被呼叫，但由於已先更新狀態，重入攻擊無效
    fallback() external payable {
        if (count < 2) {
            count++;
            // 嘗試重入，但此時 userBalances 已為 0，所以提款將失敗
            fixedWallet.withdrawBalance();
        }
    }

    // 提取累積在本合約中的 Ether
    function collectEther() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}

/*
修正後的流程說明 (繁體中文)：
1. 部署 FixedWallet 合約。
2. 部署 AttackFixed 合約，並將 FixedWallet 的 payable 地址傳入其構造子。
3. 當 AttackFixed 執行 attack() 時，FixedWallet 會先將用戶餘額（userBalances[msg.sender]）設為 0，再進行 Ether 的轉移。
4. 因此，即使 AttackFixed 在 fallback() 中嘗試重入，餘額已經被更新為 0，攻擊無法成功進行多次提款。
5. 此修正版有效地避免了 Unsafe Credit Transfer 漏洞的利用。
*/