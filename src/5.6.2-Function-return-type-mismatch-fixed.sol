pragma solidity >=0.8.0;

// 修正後的程式碼將 ownerOf 的回傳類型修正為 address，以符合介面定義

// 定義正確的介面
interface IToken {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract TokenFixed is IToken {
    // 儲存 token 擁有者
    mapping(uint256 => address) internal _owners;
    
    // 正確實作 ownerOf，回傳 token 擁有者位址
    function ownerOf(uint256 tokenId) external view override returns (address) {
        return _owners[tokenId];
    }
    
    // 鑄幣函式
    function mint(uint256 tokenId) external {
        _owners[tokenId] = msg.sender;
    }
}

contract Aline {
    // 定義 tokenId 為全域變數
    uint256 public tokenId;

    // 修正後的轉移函式會正確檢查 token 擁有者必須等於 msg.sender
    function transfer(address token) external {
        // require 條件修正：確認真正的 owner 為呼叫者
        require(IToken(token).ownerOf(tokenId) == msg.sender, "Not owner");
        
        // 以下為轉移邏輯（簡化版本）
        // ...
    }
}

// 攻擊程式碼說明：
// 修正後，由於 ownerOf 正確回傳 address，
// Bob 合約（此處為 Aline）的轉移檢查能正確判斷真正的 token 擁有者，
// 攻擊者無法藉由錯誤的返回類型使 require 條件誤判，從而避免資產被挪用。
