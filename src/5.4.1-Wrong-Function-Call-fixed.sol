// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// 正確的 Reservable 介面定義
interface IReservable {
    function reserve(uint seats) external payable;
}

// ================= Correct Reservation (真實餐廳合約) =====================
// 此合約模擬一家正規餐廳，實現 reserve 函式
contract RealRestaurant is IReservable {
    event ReservationMade(address indexed from, uint seats, uint value);

    // reserve 函式用以正確處理預訂
    function reserve(uint seats) external payable override {
        // 驗證轉入的金額必須正好為 1 ether
        require(msg.value == 1 ether, "Incorrect amount");
        emit ReservationMade(msg.sender, seats, msg.value);
        // 可以在此加入餐廳的後續邏輯處理
    }

    receive() external payable { }
}

// ================= Fixed FoodBudgetWallet Contract =====================
contract FoodBudgetWallet_Fixed {
    // 正確的餐廳地址，應指向實際的 RealRestaurant 合約地址
    address payable constant private _restaurant = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);

    constructor() payable { }

    // 正確呼叫 Reserve 合約中的 reserve 函式
    function makeReservation(uint seats) public {
        IReservable r = IReservable(_restaurant);
        r.reserve{value: 1 ether}(seats);
    }

    receive() external payable { }
}

// ================= 攻擊嘗試合約（漏洞修正後不可利用） =====================
// 此合約模擬攻擊，但由於 _restaurant 地址已正確指向 RealRestaurant，
// 因此攻擊者無法利用錯誤的函式呼叫進行惡意操作
contract AttackAttempt_Fixed {
    FoodBudgetWallet_Fixed public victim;
    RealRestaurant public realRestaurant;

    constructor() payable {
        // 部署正確的餐廳合約
        realRestaurant = new RealRestaurant();
        // 部署修正後的 FoodBudgetWallet 並假定 _restaurant 已設定為正確地址
        victim = new FoodBudgetWallet_Fixed();
    }

    // 試圖攻擊的函式，但由於 victim 的 makeReservation 正確呼叫 RealRestaurant
    // 故不存在資金被竊取的漏洞
    function executeAttack(uint seats) external payable {
        require(msg.value >= 1 ether, "min 1 ether required");
        victim.makeReservation(seats);
    }

    receive() external payable { }
}
