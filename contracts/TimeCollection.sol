// SPDX-License-Identifier: Undefined
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "solidity-json-writer/contracts/JsonWriter.sol";
import "base64-sol/base64.sol";

contract TimeCollection is ERC721, Ownable {
    using JsonWriter for JsonWriter.Json;

    uint256 private tokenCounter;

    string public COLLECTION_NAME;
    string public COLLECTION_SYMBOL;

    mapping(uint256 => Token) public allTokens;

    event MintedNFT(uint256 indexed tokenId, string tokenURI);

    struct Token {
        uint256 tokenId;
        string name;
        string description;
        string work;
        string time;
        string date;
        address payable mintedBy;
        address payable previousOwner;
        uint256 price;
        uint256 numberOfTransfers;
        bool forSale;
    }

    modifier onlyExistingTokenId(uint256 tokenId) {
        require(_exists(tokenId), "Token doesn't exist");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "Only token owner can do this");
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        COLLECTION_NAME = name;
        COLLECTION_SYMBOL = symbol;
        tokenCounter = 0;
    }

    function mint(
        string memory name,
        string memory description,
        string memory work,
        string memory time,
        string memory date
    ) public {
        _safeMint(msg.sender, tokenCounter);
        Token memory newToken = Token(
            tokenCounter,
            name,
            description,
            work,
            time,
            date,
            payable(msg.sender),
            payable(address(0)),
            0,
            0,
            false
        );
        allTokens[tokenCounter] = newToken;
        tokenCounter++;
    }

    function buyToken(uint256 tokenId) public payable onlyExistingTokenId(tokenId) {
        require(msg.sender != address(0), "Zero address is not allowed");
        address payable owner = payable(ownerOf(tokenId));
        require(owner != msg.sender, "You can't buy your own token");
        Token memory token = allTokens[tokenId];
        require(token.forSale, "Token is not for sale");
        require(msg.value >= token.price, "Ether value is not enough");
        token.previousOwner = owner;
        token.forSale = false;
        token.numberOfTransfers++;
        allTokens[tokenId] = token;
        _transfer(owner, msg.sender, tokenId);
        owner.transfer(msg.value);
    }

    function changeTokenPrice(uint256 tokenId, uint256 newPrice)
        public
        onlyExistingTokenId(tokenId)
        onlyTokenOwner(tokenId)
    {
        allTokens[tokenId].price = newPrice;
    }

    function toggleForSale(uint256 tokenId) public onlyExistingTokenId(tokenId) onlyTokenOwner(tokenId) {
        Token memory token = allTokens[tokenId];
        token.forSale = !token.forSale;
        allTokens[tokenId] = token;
    }

    function tokenURI(uint256 tokenId) public view override onlyExistingTokenId(tokenId) returns (string memory) {
        Token memory token = allTokens[tokenId];
        JsonWriter.Json memory writer;

        writer = writer.writeStartObject();

        writer = writer.writeStringProperty("name", token.name);
        writer = writer.writeStringProperty("description", token.description);

        writer = writer.writeStartArray("attributes");

        writer = writer.writeStartObject();
        writer = writer.writeStringProperty("trait_type", "type");
        writer = writer.writeStringProperty("value", token.work);
        writer = writer.writeEndObject();

        writer = writer.writeStartObject();
        writer = writer.writeStringProperty("trait_type", "Number of Hours");
        writer = writer.writeStringProperty("value", token.time);
        writer = writer.writeEndObject();

        writer = writer.writeStartObject();
        writer = writer.writeStringProperty("trait_type", "Date");
        writer = writer.writeStringProperty("value", token.date);
        writer = writer.writeEndObject();

        writer = writer.writeEndArray();

        writer = writer.writeEndObject();

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(writer.value))));
    }
}
