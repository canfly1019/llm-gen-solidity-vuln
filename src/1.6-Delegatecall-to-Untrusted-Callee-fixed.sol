pragma solidity >=0.8.0;

// 修正後的程式碼：透過限制只有 owner 可設定委派呼叫的目標合約 (callee)，
// 防止任意呼叫 delegatecall 從而導致狀態變數被修改。

contract ProxyFixed {
    // 狀態變數：僅允許由 owner 設定委派目標合約
    address public callee;
    address public owner;
    
    constructor() {
        owner = msg.sender;
        callee = address(0);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // 僅允許所有者設定可委派的 target 合約
    function setCallee(address _newCallee) public onlyOwner {
        callee = _newCallee;
    }
    
    // forward 函數現在只委派呼叫預先設定且信任的合約
    function forward(bytes memory _data) public {
        require(callee != address(0), "callee not set");
        (bool success, ) = callee.delegatecall(_data);
        require(success, "delegatecall failed");
    }
}

// 範例中的惡意合約，若不小心被 set 為 ProxyFixed 的 callee，仍能造成 owner 變數被修改
// 但由於只有 owner 有權設定 callee，攻擊者無法自行將惡意合約設置到 ProxyFixed
contract Malicious {
    function pwn() public {
        assembly {
            // 試圖修改 storage slot 0 (ProxyFixed.owner) 為呼叫者位址，但如果 ProxyFixed.callee 不是由 owner 設置，
            // 則此惡意合約無法被設定，使攻擊無法發生
            sstore(0, caller())
        }
    }
}

/* 修正後的防護說明：
   1. 僅允許所有者透過 setCallee() 設定委派目標合約，降低攻擊面。
   2. forward() 僅能委派預先設定且信任的合約，避免任意委派攻擊的發生。
   3. 若不小心設定了不安全的合約，依然可以由 owner 及時更換目標合約。
*/
