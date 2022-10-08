// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {IERC721} from "openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC721Contract} from "../../src/oz/ERC721Contract.sol";

contract EnglishAuctionTest is Test {
    //
    EnglishAuction auction;

    IERC721 token;

    address seller = address(0xA1);
    address bidder1 = address(0xB1);

    function setUp() public {
        vm.deal(bidder1, 10 ether);

        token = new ERC721Contract();

        vm.prank(seller);
        auction = new EnglishAuction(token, 0.1 ether, 0.1 ether, 1 days);
    }

    function test_initial() public {
        assertEq(auction.seller(), seller);

        assertEq(address(auction.token()), address(token));
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
        auction.placeBid{value: 1.1 ether}(1.09 ether); // wrong amount, ess

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

    function test_placeBid_whenBelowReservePrice_shouldRevert() public {
        vm.expectRevert("EnglishAuction: bid does not meet reserve price");

        vm.prank(bidder1);
        auction.placeBid{value: 0.09 ether}(0.09 ether);
    }

    function test_placeBid_whenBelowminIncrementInEthAbovePreviousHighBid_shouldRevert() public {
        vm.prank(bidder1);
        auction.placeBid{value: 0.1 ether}(0.1 ether);

        vm.expectRevert("EnglishAuction: bid does not meet minimum increment above previous high bid");

        // for now, allow overbidding
        vm.prank(bidder1);
        auction.placeBid{value: 0.109 ether}(0.109 ether);
    }

    // 
}

library AuctionEvents {
    event BidPlaced(address highBidder, uint256 highBid);
}

contract EnglishAuction {
    //
    address public seller;

    IERC721 public token;
    uint256 public reservePrice;
    uint256 public minIncrementInEth;
    uint256 public timeoutPeriod;

    uint256 public auctionEnd;

    mapping(address => uint256) public balanceOf;

    address public highBidder;    

    constructor(IERC721 _token, uint256 _reservePrice, uint256 _minIncrementInEth, uint256 _timeoutPeriod) {
        seller = msg.sender;

        token = _token;
        reservePrice = _reservePrice;
        minIncrementInEth = _minIncrementInEth;
        timeoutPeriod = _timeoutPeriod;

        auctionEnd = block.timestamp + timeoutPeriod;
    }

    function placeBid(uint256 bidAmount) public payable {
        require(block.timestamp < auctionEnd, "EnglishAuction: cannot place bid after auction has ended");
        require(bidAmount >= reservePrice, "EnglishAuction: bid does not meet reserve price");
        require(bidAmount >= balanceOf[highBidder] + minIncrementInEth, "EnglishAuction: bid does not meet minimum increment above previous high bid");

        balanceOf[msg.sender] += msg.value;
        require(balanceOf[msg.sender] == bidAmount, "EnglishAuction: bid amount does not match included value");

        highBidder = msg.sender;

        emit AuctionEvents.BidPlaced(highBidder, bidAmount);
    }
}

