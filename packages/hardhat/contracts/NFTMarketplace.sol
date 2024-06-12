// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NFTMarketplace is ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Address for address payable;

    address payable public marketplaceOwner;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemSold;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private marketItems;

    event ItemListed(uint256 indexed itemId, address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price);
    event ItemSold(uint256 indexed itemId, address indexed nftContract, uint256 indexed tokenId, address buyer, uint256 price);

    constructor() ERC721("NFTMarketplace", "NFTM") {
        marketplaceOwner = payable(msg.sender);
    }

    function listNFT(address _nftContract, uint256 _tokenId, uint256 _price) external {
        require(_nftContract != address(0), "Invalid NFT contract address");
        require(_price > 0, "Price must be greater than zero");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        marketItems[itemId] = MarketItem(itemId, _nftContract, _tokenId, payable(msg.sender), _price, false);

        emit ItemListed(itemId, _nftContract, _tokenId, msg.sender, _price);
    }

    function buyNFT(uint256 _itemId) external payable nonReentrant {
        require(_itemId > 0 && _itemId <= _itemIds.current(), "Invalid item id");
        MarketItem storage item = marketItems[_itemId];
        require(!item.sold, "Item already sold");
        require(msg.value >= item.price, "Insufficient funds");

        item.sold = true;
        _itemSold.increment();
        _transfer(item.seller, msg.sender, item.nftContract, item.tokenId);

        item.seller.sendValue(msg.value);
        emit ItemSold(_itemId, item.nftContract, item.tokenId, msg.sender, item.price);
    }

    function _transfer(address _from, address _to, address _nftContract, uint256 _tokenId) private {
        ERC721Enumerable(_nftContract).safeTransferFrom(_from, _to, _tokenId);
    }

    function totalItems() external view returns (uint256) {
        return _itemIds.current();
    }

    function totalItemsSold() external view returns (uint256) {
        return _itemSold.current();
    }
}