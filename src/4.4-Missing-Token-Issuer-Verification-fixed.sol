pragma solidity ^0.8.0;

/*
FixedTicket 合約說明：
1. 修正方法：在 transfer 函式中增加對 msg.sender 是否為 tokenIssuer 的檢查，確保只有合法的 token 發行者可以觸發獎勵發放邏輯。
2. 攻擊者再無法通過直接呼叫 transfer 而獲取獎勵，避免了充值票費機制被濫用的漏洞。

修正步驟：
1. 呼叫 transfer() 時，檢查 msg.sender 是否為 tokenIssuer，否則拋出錯誤。
*/

contract FixedTicket {
    address public tokenIssuer;
    address public sponsor;

    constructor(address _tokenIssuer, address _sponsor) {
        tokenIssuer = _tokenIssuer;
        sponsor = _sponsor;
    }

    // 修正後的 transfer 函式，檢查 msg.sender 是否為 tokenIssuer
    function transfer() external payable {
        // 修正重點：增加 require 驗證 token issuer
        require(msg.sender == tokenIssuer, "Caller is not token issuer");
        runSponsor();
    }

    function otherAction() external payable {
        require(msg.sender == tokenIssuer || msg.sender == address(this), "Not allowed");
        // 正常執行其他功能
    }

    // runSponsor 函式，專責將合約內餘額發送給呼叫者
    function runSponsor() internal {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}

/*
修正後的使用示例：
- 僅允許 tokenIssuer 呼叫 transfer()。因此，攻擊者無法以非 tokenIssuer 身份觸發 runSponsor()。
- 正常情況下，只能由合法發行者操作，確保票費和其他商業邏輯正確執行。

測試步驟：
1. 直接由 tokenIssuer 地址呼叫 transfer()，操作成功，獎勵發放符合預期。
2. 攻擊者（非 tokenIssuer）呼叫 transfer() 會觸發 require，交易失敗。
*/
