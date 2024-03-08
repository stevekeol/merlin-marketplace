// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


// 这段代码是一个简单的NFT（非同质化代币）市场智能合约，用于创建一个简单的NFT交易市场
// 
// 合约继承关系：该合约继承了ERC721Enumerable、Ownable和ReentrancyGuard三个合约，分别用于实现NFT代币、所有权控制和防止重入攻击。
contract Marketplace is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // 变量定义：定义了baseURI（基本URI）、whitelist（白名单）、listedPrices（挂单价格）、_listedOwners（挂单所有者）、_pendingWithdrawals（待提现金额）等变量。
    string baseURI;
    mapping(address => bool) public whitelist;
    mapping(uint256 => uint256) public listedPrices;
    mapping(uint256 => address) private _listedOwners;
    mapping(address => uint256) private _pendingWithdrawals;


    // 构造函数：在构造函数中初始化了合约的名称、符号和基本URI。
    constructor(string memory name, string memory symbol, string memory baseUri) ERC721(name, symbol) {
        baseURI = baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // mintNFT函数：用于铸造新的NFT，并要求调用者在白名单中。
    function mintNFT(address to, uint256 tokenId) public {
        require(whitelist[msg.sender], "Caller is not on the whitelist");
        _mint(to, tokenId);
    }

    // setWhitelist函数：用于设置白名单，只有合约所有者可以调用。
    function setWhitelist(address addr, bool isWhitelisted) external onlyOwner {
        whitelist[addr] = isWhitelisted;
    }

    // listNFT函数：将NFT挂单出售，要求调用者是NFT的所有者，并且价格大于0。
    function listNFT(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        require(price > 0, "Price must be at least 1 wei");

        _listedOwners[tokenId] = msg.sender;
        listedPrices[tokenId] = price;
        approve(address(this), tokenId);
    }

    // cancelListing函数：取消NFT的挂单，要求调用者是NFT的挂单所有者。
    function cancelListing(uint256 tokenId) public {
        require(_listedOwners[tokenId] == msg.sender, "Caller is not the token owner");
        listedPrices[tokenId] = 0;
        _listedOwners[tokenId] = address(0);
        approve(address(0), tokenId);
    }

    // buyNFT函数：购买NFT，要求支付足够的金额，并且NFT已经被批准出售
    function buyNFT(uint256 tokenId) public payable nonReentrant {
        uint256 price = listedPrices[tokenId];
        address seller = _listedOwners[tokenId];
        require(price > 0, "This NFT is not for sale");
        require(msg.value >= price, "Insufficient payment");
        require(getApproved(tokenId) == address(this), "NFT not approved for sale");

        _pendingWithdrawals[seller] += msg.value;
        listedPrices[tokenId] = 0;
        _listedOwners[tokenId] = address(0);
        
        _transfer(seller, msg.sender, tokenId);
    }

    // withdraw函数的作用是允许合约的调用者（msg.sender）提取其在合约中的待提现金额（_pendingWithdrawals[msg.sender]）

    // 1.获取调用者待提现的金额。
    // 2.检查待提现金额是否大于0，如果不大于0则抛出异常提示"没有资金可提取"。
    // 3.将调用者的待提现金额设为0，表示已经提现。
    // 4.使用payable修饰符将msg.sender转换为payable地址，并调用transfer函数将待提现金额转账给调用者。

    function withdraw() public nonReentrant {
        uint amount = _pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        _pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
