pragma solidity >=0.8.0;

// 修正後的合約：避免使用與保留字相同的變數與函數名稱，並正確初始化應用中的時間變數

contract BugFixed {
    // 將變數名稱改為 agora 並公開，並在部署時初始化為當前區塊時間
    uint public agora;

    constructor() {
        agora = block.timestamp;
    }

    // 改名為 assertAgora 避免與內建的 assert 衝突，並示範基本的斷言行為
    function assertAgora(bool condition) public pure {
        require(condition, "Assertion failed");
    }

    // 修改為 public，這裡使用正確初始化的 agora 來計算到期時間
    function get_next_expiration(uint earlier_time) public view returns (uint) {
        // 正確地使用初始化的 agora 變數來計算預期的到期時間
        return agora + 259200;
    }
}

// 修正後的攻擊示意合約：在此案例中攻擊行為僅用來展示漏洞已被修補
contract AttackFixed {
    BugFixed public fixedContract;

    // 部署 AttackFixed 時需要傳入 BugFixed 合約的地址
    constructor(address _fixedAddress) {
        fixedContract = BugFixed(_fixedAddress);
    }

    // 此函數僅用於呼叫 get_next_expiration 並取得計算結果
    function attackFixed() public view returns (uint) {
        return fixedContract.get_next_expiration(block.timestamp);
    }
}

/*
部署與測試步驟：
1. 部署 BugFixed 合約，其內部變數 agora 會被初始化為部署時的 block.timestamp。
2. 部署 AttackFixed 合約，傳入 BugFixed 合約的地址。
3. 呼叫 AttackFixed 合約中的 attackFixed 函數，將正確返回 agora + 259200，反映正確的計算結果。
*/