pragma solidity >=0.8.0;
// SPDX-License-Identifier: UNLICENSED

// 修正後的版本：所有狀態變數皆明確指定可見性，防止未授權存取

contract TestStorageFixed {
    uint constant constuint = 16;
    mapping (address => uint) public uints1;
    
    // 將不需外部存取的 mapping 標記為 private
    mapping (address => DeviceData) private structs1;
    
    // 明確設為 private，避免外部直接讀取或操作
    uint[] private uintarray;
    
    // 明確設為 private，避免外部直接讀取或操作
    DeviceData[] private deviceDataArray;
    
    // 裝置資料結構定義
    struct DeviceData {
        string deviceBrand;
        string deviceYear;
        string batteryWearLevel;
    }
    
    // 測試函式，用來初始化與儲存資料
    function testStorage() public {
        // 使用正確 checksum 的地址
        address address1 = 0xbCcc714d56bc0da0fd33d96d2a87b680dD6D0DF6;
        address address2 = 0xaee905FdD3ED851e48d22059575b9F4245A82B04;
        
        uints1[address1] = 88;
        uints1[address2] = 99;
        
        DeviceData memory dev1 = DeviceData("deviceBrand", "deviceYear", "wearLevel");
        structs1[address1] = dev1;
        
        uintarray.push(8000);
        uintarray.push(9000);
        
        deviceDataArray.push(dev1);
    }
    
    // 提供受控 getter 介面，允許外部讀取必要資訊
    function getUintArrayLength() public view returns (uint) {
        return uintarray.length;
    }
    
    function getDeviceDataArrayLength() public view returns (uint) {
        return deviceDataArray.length;
    }
}

/*
說明：
在此修正版本中，我們將所有不需外部存取的狀態變數（如 structs1, uintarray 與 deviceDataArray）
明確指定為 private，以防止其他合約透過繼承進行不當存取。
同時，使用正確 checksum 的地址來避免編譯錯誤。
*/