// Solidity version >=0.8.0
pragma solidity >=0.8.0;

/*
Fixed Code:
Fixes in the setDiscount function:
1. Only the admin (contract owner) is allowed to change the discount.
2. The input _discount is validated to ensure it is between 0 and 100.

With these changes, an attacker cannot set an invalid discount value. If an attempt is made, the transaction reverts with an English error message.
*/

contract SaleEventFixed {
    address public admin;
    uint public discount; // Discount percentage must be between 0 and 100
    uint public basePrice = 100 ether;

    constructor() {
        admin = msg.sender;
        discount = 0;
    }

    // Fixed: Only admin can call this function and _discount must be <= 100
    function setDiscount(uint _discount) public {
        require(msg.sender == admin, "Only admin can update discount");
        require(_discount <= 100, "Invalid discount");
        discount = _discount;
    }

    function buy() public payable {
        uint finalPrice = basePrice * (100 - discount) / 100;
        require(msg.value >= finalPrice, "Insufficient Ether sent");
        if (msg.value > finalPrice) {
            payable(msg.sender).transfer(msg.value - finalPrice);
        }
    }
}

// Attack contract attempting to target the fixed contract
contract AttackSaleFixed {
    SaleEventFixed public sale;

    constructor(address _sale) {
        sale = SaleEventFixed(_sale);
    }

    // Attempt to attack by setting an invalid discount; this should revert
    function attack() public {
        // This call will revert because only the admin can update discount and discount value must be <= 100
        sale.setDiscount(101);
    }

    function maliciousBuy() public payable {
        sale.buy{value: msg.value}();
    }
}
