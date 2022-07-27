// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";
import {ERC721Contract} from "../src/sm/ERC721Contract.sol";

abstract contract ReserveAuctionCoreEth {
    //
    function createAuction(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _reservePrice,
        address _sellerFundsRecipient,
        uint256 _startTime
    ) public virtual;

    function setAuctionReservePrice(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _reservePrice
    ) public virtual;

    function cancelAuction(address _tokenContract, uint256 _tokenId) public virtual;

    function createBid(address _tokenContract, uint256 _tokenId) public virtual;

    function settleAuction(address _tokenContract, uint256 _tokenId) public virtual;

    /// @dev ERC-721 token contract => ERC-721 token id => Auction
    mapping(address => mapping(uint256 => Auction)) public auctionForNFT;
}

struct Auction {
    address seller;
    uint96 reservePrice;
    address sellerFundsRecipient;
    uint96 highestBid;
    address highestBidder;
    uint32 duration;
    uint32 startTime;
    uint32 firstBidTime;
}

contract ZoraTest is Test {
    //
    ReserveAuctionCoreEth zAuction;
    ERC721Contract nft;

    function setUp() public {
        vm.createSelectFork(ROPSTEN_RPC_URL, 12673131);
        zAuction = ReserveAuctionCoreEth(address(0xF57A73D355680Df3945Da7853A1F1F9149C7DA4D));
        nft = new ERC721Contract("Handrolled NFT", "ROLLUP");
    }

    function testHelloWorld() public {
        nft.mint(address(0xBABE), 1337);
        vm.prank(address(0xBABE));
        zAuction.createAuction(address(nft), 1337, 3 days, 0.1 ether, address(0xABCD), block.timestamp);

        (
            address creator,
            uint256 reservePrice,
            address fundsRecipient,
            ,
            ,
            uint256 duration,
            uint256 startTime,

        ) = zAuction.auctionForNFT(address(nft), 1337);

        assertEq(creator, address(0xBABE));
        assertEq(reservePrice, 0.1 ether);
        assertEq(fundsRecipient, address(0xABCD));
        assertEq(duration, 3 days);
        assertEq(startTime, block.timestamp);
    }

    function testCreateAuctionWhenOperator() public {
        nft.mint(address(0xBABE), 1337);
        vm.prank(address(0xBABE));
        nft.setApprovalForAll(address(0xABCD), true);

        vm.prank(address(0xABCD));
        zAuction.createAuction(address(nft), 1337, 3 days, 0.1 ether, address(0xABCD), block.timestamp);

        (address creator, , , , , , , ) = zAuction.auctionForNFT(address(nft), 1337);

        assertEq(creator, address(0xBABE));
    }

    function testCreateAuctionWhenNotOwnerOrOperatorShouldFail() public {
        nft.mint(address(0xBABE), 1337);

        vm.expectRevert("ONLY_TOKEN_OWNER_OR_OPERATOR");
        zAuction.createAuction(address(nft), 1337, 3 days, 0.1 ether, address(0xABCD), block.timestamp);
    }
}
