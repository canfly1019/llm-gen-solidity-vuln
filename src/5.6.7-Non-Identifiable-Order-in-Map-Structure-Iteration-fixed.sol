// Fixed Code
// 修正後的合約已加入檢查機制，避免相同的 order id 重複被加入
// 修正內容：
// 1. 透過 orderExists mapping 紀錄每個 order id 是否已存在，若已存在則拒絕新增。
// 2. 確保 orderIds 陣列中不會有重複的值，從而在 processOrders 時只處理每個訂單一次。

pragma solidity >=0.8.0;

contract FixedOrderProcessor {
    // 訂單結構
    struct Order {
        uint id;           // 訂單編號
        uint amount;       // 訂單金額
        address buyer;     // 購買者
    }
    
    // 狀態變數：
    mapping(uint => Order) public orders;
    uint[] public orderIds;
    mapping(uint => bool) private orderExists; // 新增的存在性檢查 mapping
    
    // 新增訂單，檢查是否已存在相同 order id
    function addOrder(uint _id, uint _amount) public payable {
        require(!orderExists[_id], "Order already exists"); // 已存在則拒絕
        orders[_id] = Order(_id, _amount, msg.sender);
        orderIds.push(_id);
        orderExists[_id] = true; // 標記為已存在
    }
    
    // 處理所有訂單
    function processOrders() public {
        for (uint i = 0; i < orderIds.length; i++) {
            uint id = orderIds[i];
            Order memory order = orders[id];
            processOrder(order);
        }
        // 清除 orderIds 陣列（注意：若有需要保留已處理記錄，應另行設計）
        delete orderIds;
    }
    
    event OrderProcessed(uint id, uint amount, address buyer);
    
    // 模擬訂單處理邏輯
    function processOrder(Order memory order) internal {
        emit OrderProcessed(order.id, order.amount, order.buyer);
    }
    
    // 接收 Ether
    receive() external payable {}
}

/*
修正測試說明：
1. 部署 FixedOrderProcessor 合約。
2. 當嘗試呼叫 addOrder(1, 100) 第二次時，require 檢查將拒絕操作，避免相同 order id 被重複加入。
3. 呼叫 processOrders 時，每個訂單只會被處理一次，從而避免 ledger 狀態不一致的問題。
*/
