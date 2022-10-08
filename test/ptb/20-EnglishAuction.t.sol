// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {IERC721} from "openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC721Contract} from "../../src/oz/ERC721Contract.sol";

// imspired by https://programtheblockchain.com/posts/2018/03/20/writing-a-token-auction-contract/
contract EnglishAuctionTest is Test {
    //
    EnglishAuction auction;

    ERC721Contract token;

    address seller = address(0xA1);
    address bidder1 = address(0xB1);
    address bidder2 = address(0xB2);

    function setUp() public {
        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 10 ether);

        token = new ERC721Contract();

        vm.prank(seller);
        auction = new EnglishAuction(address(token), 1, 0.1 ether, 0.1 ether, 1 days);

        token.mint(address(auction), 1); // the item up for auction
    }

    function test_initial() public {
        assertEq(auction.seller(), seller);

        assertEq(auction.tokenContract(), address(token));
        assertEq(auction.tokenId(), 1);
        assertEq(auction.reservePrice(), 0.1 ether);
        assertEq(auction.minIncrementInEth(), 0.1 ether);
        assertEq(auction.timeoutPeriod(), 1 days);

        assertEq(auction.auctionEnd(), block.timestamp + 1 days);
    }

    function test_placeBid() public {
        vm.expectEmit(true, true, true, true);
        emit AuctionEvents.BidPlaced(bidder1, 0.1 ether);

        vm.prank(bidder1);
        auction.placeBid{value: 0.1 ether}(0.1 ether);

        assertEq(auction.balanceOf(bidder1), 0.1 ether);
        assertEq(address(auction).balance, 0.1 ether);
        assertEq(bidder1.balance, 9.9 ether);

        assertEq(auction.highBidder(), bidder1);
    }

    function test_placeBid_whenAmountDoesNotMatchIncludedValue_shouldRevert() public {
        vm.expectRevert("EnglishAuction: bid amount does not match included value");

        vm.prank(bidder1);
        auction.placeBid{value: 1.1 ether}(1.11 ether); // wrong amount, more

        vm.expectRevert("EnglishAuction: bid amount does not match included value");

        vm.prank(bidder1);
        auction.placeBid{value: 1.1 ether}(1.09 ether); // wrong amount, less

        vm.expectRevert("EnglishAuction: bid amount does not match included value");

        vm.prank(bidder1);
        auction.placeBid{value: 1.11 ether}(1.1 ether); // wrong value, more

        vm.expectRevert("EnglishAuction: bid amount does not match included value");

        vm.prank(bidder1);
        auction.placeBid{value: 1.09 ether}(1.1 ether); // wrong value, less
    }

    function test_placeBid_whenAfterEndOfAuction_shouldRevert() public {
        vm.warp(block.timestamp + 1 days + 1 seconds);

        vm.expectRevert("EnglishAuction: cannot place bid after auction has ended");

        vm.prank(bidder1);
        auction.placeBid{value: 0.1 ether}(0.1 ether);
    }

    function test_placeBid_whenLessThanReservePrice_shouldRevert() public {
        vm.expectRevert("EnglishAuction: bid does not meet reserve price");

        vm.prank(bidder1);
        auction.placeBid{value: 0.09 ether}(0.09 ether);
    }

    function test_placeBid_whenLessThanMinIncrementAbovePreviousHighBid_shouldRevert() public {
        vm.prank(bidder1);
        auction.placeBid{value: 0.1 ether}(0.1 ether);

        vm.expectRevert("EnglishAuction: bid does not meet minimum increment above previous high bid");

        // for now, allow overbidding
        vm.prank(bidder1);
        auction.placeBid{value: 0.109 ether}(0.109 ether);
    }

    function test_withdraw() public {
        vm.prank(bidder1);
        auction.placeBid{value: 0.1 ether}(0.1 ether);

        vm.prank(bidder2);
        auction.placeBid{value: 0.2 ether}(0.2 ether);

        // precondition checks
        assertEq(bidder1.balance, 9.9 ether);
        assertEq(bidder2.balance, 9.8 ether);
        assertEq(address(auction).balance, 0.3 ether);
        assertEq(auction.balanceOf(bidder1), 0.1 ether);
        assertEq(auction.balanceOf(bidder2), 0.2 ether);

        vm.prank(bidder1);
        auction.withdraw();

        assertEq(bidder1.balance, 10 ether);
        assertEq(bidder2.balance, 9.8 ether); // no change
        assertEq(address(auction).balance, 0.2 ether);
        assertEq(auction.balanceOf(bidder1), 0 ether);
        assertEq(auction.balanceOf(bidder2), 0.2 ether); // no change
    }

    function test_withdraw_whenHighBidder_shouldRevert() public {
        vm.prank(bidder1);
        auction.placeBid{value: 0.1 ether}(0.1 ether);

        vm.expectRevert("EnglishAuction: cannot withdraw escrowed bid when it is the current high bid");

        vm.prank(bidder1);
        auction.withdraw();

        // check again, when multiple bids have been placed
        vm.prank(bidder2);
        auction.placeBid{value: 0.2 ether}(0.2 ether);

        vm.expectRevert("EnglishAuction: cannot withdraw escrowed bid when it is the current high bid");

        vm.prank(bidder2);
        auction.withdraw();
    }

    function test_settleAuction_whenWinningBid() public {
        vm.prank(bidder1);
        auction.placeBid{value: 0.1 ether}(0.1 ether);

        // precondition checks
        assertEq(token.ownerOf(1), address(auction));
        assertEq(auction.balanceOf(seller), 0 ether);
        assertEq(auction.balanceOf(bidder1), 0.1 ether);
        assertEq(auction.highBidder(), bidder1);

        vm.warp(auction.auctionEnd());

        vm.expectEmit(true, true, true, true);
        emit AuctionEvents.AuctionEndedWithWinningBid(address(token), 1, bidder1, 0.1 ether);

        auction.settleAuction(); // anyone can call

        assertEq(token.ownerOf(1), bidder1);
        assertEq(auction.balanceOf(seller), 0.1 ether);
        assertEq(auction.balanceOf(bidder1), 0 ether);
        assertEq(auction.highBidder(), address(0));
    }

    function test_settleAuction_whenNoWinningBid() public {
        // precondition checks
        assertEq(token.ownerOf(1), address(auction));

        vm.warp(auction.auctionEnd());

        vm.expectEmit(true, true, true, true);
        emit AuctionEvents.AuctionEndedWithNoWinningBid(address(token), 1);

        auction.settleAuction();

        assertEq(token.ownerOf(1), seller);
    }

    function test_settleAuction_whenAuctionHasNotEndedAndWinningBid_shouldRevert() public {
        vm.prank(bidder1);
        auction.placeBid{value: 0.1 ether}(0.1 ether);

        vm.expectRevert("EnglishAuction: cannot settle auction before auction has ended");

        auction.settleAuction();
    }

    function test_settleAuction_whenAuctionHasNotEndedAndNoWinningBid_shouldRevert() public {
        vm.expectRevert("EnglishAuction: cannot settle auction before auction has ended");

        auction.settleAuction();
    }
}

library AuctionEvents {
    // event AuctionCreated - would typically include this, if contract supported multiple auctions
    event BidPlaced(address highBidder, uint256 highBid);
    event AuctionEndedWithWinningBid(
        address indexed tokenContract, uint256 indexed tokenId, address indexed winningBidder, uint256 winningBidAmount
    );
    event AuctionEndedWithNoWinningBid(address indexed, uint256 indexed tokenId);
}

contract EnglishAuction {
    //
    address public seller;

    address public tokenContract;
    uint256 public tokenId;
    uint256 public reservePrice;
    uint256 public minIncrementInEth;
    uint256 public timeoutPeriod;

    uint256 public auctionEnd;

    mapping(address => uint256) public balanceOf;

    address public highBidder;

    constructor(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _reservePrice,
        uint256 _minIncrementInEth,
        uint256 _timeoutPeriod
    ) {
        seller = msg.sender;

        tokenContract = _tokenContract;
        tokenId = _tokenId;
        reservePrice = _reservePrice;
        minIncrementInEth = _minIncrementInEth;
        timeoutPeriod = _timeoutPeriod;

        auctionEnd = block.timestamp + timeoutPeriod;
    }

    function placeBid(uint256 bidAmount) public payable {
        require(block.timestamp < auctionEnd, "EnglishAuction: cannot place bid after auction has ended");
        require(bidAmount >= reservePrice, "EnglishAuction: bid does not meet reserve price");
        require(
            bidAmount >= balanceOf[highBidder] + minIncrementInEth,
            "EnglishAuction: bid does not meet minimum increment above previous high bid"
        );

        balanceOf[msg.sender] += msg.value;
        require(balanceOf[msg.sender] == bidAmount, "EnglishAuction: bid amount does not match included value");

        highBidder = msg.sender;

        emit AuctionEvents.BidPlaced(highBidder, bidAmount);
    }

    function withdraw() public {
        require(
            msg.sender != highBidder, "EnglishAuction: cannot withdraw escrowed bid when it is the current high bid"
        );

        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success);
    }

    function settleAuction() public {
        require(block.timestamp >= auctionEnd, "EnglishAuction: cannot settle auction before auction has ended");

        if (highBidder == address(0)) {
            // no winning bid - transfer item to seller
            IERC721(tokenContract).transferFrom(address(this), seller, tokenId);

            emit AuctionEvents.AuctionEndedWithNoWinningBid(tokenContract, tokenId);
        } else {
            // winning bid - transfer item to high bidder
            IERC721(tokenContract).transferFrom(address(this), highBidder, tokenId);

            // transfer winning bid to seller balance
            uint256 winningBidAmount = balanceOf[highBidder]; // small gas optimization
            balanceOf[seller] += winningBidAmount;

            emit AuctionEvents.AuctionEndedWithWinningBid(tokenContract, tokenId, highBidder, winningBidAmount);

            // clean up
            balanceOf[highBidder] = 0;
            highBidder = address(0);
        }
    }
}
