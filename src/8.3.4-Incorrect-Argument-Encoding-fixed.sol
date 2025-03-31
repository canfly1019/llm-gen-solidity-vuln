pragma solidity >=0.8.0;

// SPDX-License-Identifier: UNLICENSED

// 修正版本：改用 abi.encode 正確編碼參數，避免碰撞
// 使用正確參數編碼可以確保不同參數不會拼接成相同結果

library ECDSA {
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) {
            revert("invalid signature length");
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        // 正確的 ECDSA 邏輯請參考 OpenZeppelin ECDSA
        return address(0x1234567890123456789012345678901234567890);
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

contract FixedAccessControl {
    using ECDSA for bytes32;

    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isRegularUser;

    // 部署時初始化部署者為管理員
    constructor() {
        isAdmin[msg.sender] = true;
    }

    // 修正版本: 使用 abi.encode 以正確編碼參數，避免碰撞風險
    function addUsers(
        address[] calldata admins,
        address[] calldata regularUsers,
        bytes calldata signature
    ) external {
        if (!isAdmin[msg.sender]) {
            bytes32 hash = keccak256(abi.encode(admins, regularUsers));
            address signer = hash.toEthSignedMessageHash().recover(signature);
            require(isAdmin[signer], "Only admins can add users.");
        }

        for (uint256 i = 0; i < admins.length; i++) {
            isAdmin[admins[i]] = true;
        }
        for (uint256 i = 0; i < regularUsers.length; i++) {
            isRegularUser[regularUsers[i]] = true;
        }
    }
}

// 攻擊範例 (嘗試仿造 Vulnerable 版本攻擊，但因使用正確編碼而無法產生碰撞成功)
contract AttackFixed {
    FixedAccessControl public target;

    constructor(FixedAccessControl _target) {
        target = _target;
    }

    function performAttack(bytes calldata adminSignature) external {
        address[] memory admins = new address[](1);
        admins[0] = msg.sender;
        
        address[] memory regularUsers = new address[](1);
        // 使用正確 checksum 格式地址
        regularUsers[0] = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;

        target.addUsers(admins, regularUsers, adminSignature);
    }
}
