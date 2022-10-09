// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {IERC721} from "openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC721Contract} from "../../src/oz/ERC721Contract.sol";

// inspired by https://programtheblockchain.com/posts/2018/03/27/writing-a-sealed-bid-auction-contract/
contract SealedBidAuctionTest is Test {
    //
    SealedBidAuction auction;

    ERC721Contract token;

    address seller = address(0xA1);
    address bidder1 = address(0xB1);
    address bidder2 = address(0xB2);

    bytes32 bidder1nonce = bytes32("setec astronomy");
    bytes32 bidder2nonce = bytes32("too many secrets");

    function setUp() public {
        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 10 ether);

        token = new ERC721Contract();

        vm.prank(seller);
        auction = new SealedBidAuction(
            address(token),
            1,
            1 ether,
            2 days,
            1 days
        );

        token.mint(address(auction), 1);
    }

    function test_initial() public {
        assertEq(auction.seller(), seller);
        assertEq(auction.highBidder(), seller);

        assertEq(auction.tokenContract(), address(token));
        assertEq(auction.tokenId(), 1);
        assertEq(auction.reservePrice(), 1 ether);

        assertEq(auction.endOfBidding(), block.timestamp + 2 days);
        assertEq(auction.endOfRevealing(), block.timestamp + 2 days + 1 days);
    }

    function test_placeBid() public {
        bytes32 sealedBid = genSealedBid(1 ether, bidder1nonce);

        vm.prank(bidder1);
        auction.placeBid{value: 1 ether}(sealedBid);

        assertEq(address(auction).balance, 1 ether);
        assertEq(auction.balanceOf(bidder1), 1 ether);
        assertEq(auction.sealedBidOf(bidder1), sealedBid);
    }

    function test_placeBid_whenAfterBiddingPeriod_shouldRevert() public {
        vm.warp(block.timestamp + 2 days + 1 seconds);

        bytes32 sealedBid = genSealedBid(1 ether, bidder1nonce);

        vm.expectRevert("SBA: cannot place bid once bidding period is over");

        vm.prank(bidder1);
        auction.placeBid{value: 1 ether}(sealedBid);
    }

    function test_placeBid_whenBidderAlreadyPlacedBid_shouldRevert() public {
        bytes32 sealedBid = genSealedBid(1 ether, bidder1nonce);

        vm.prank(bidder1);
        auction.placeBid{value: 1 ether}(sealedBid);

        vm.expectRevert("SBA: cannot place more than one bid");

        bytes32 sealedBid2 = keccak256(abi.encodePacked(uint256(2 ether), bidder1nonce));

        vm.prank(bidder1);
        auction.placeBid{value: 2 ether}(sealedBid2);
    }

    function test_placeBid_whenLessThanReservePrice_shouldRevert() public {
        bytes32 sealedBid = genSealedBid(0.99 ether, bidder1nonce);

        vm.expectRevert("SBA: bid amount cannot be less than reserve price");

        vm.prank(bidder1);
        auction.placeBid{value: 0.99 ether}(sealedBid);
    }

    function test_placeBid_whenMultipleBidders() public {
        bytes32 sealedBid1 = genSealedBid(1 ether, bidder1nonce);
        bytes32 sealedBid2 = genSealedBid(1.5 ether, bidder2nonce);

        vm.prank(bidder1);
        auction.placeBid{value: 1 ether}(sealedBid1);
        vm.prank(bidder2);
        auction.placeBid{value: 1.5 ether}(sealedBid2);

        assertEq(address(auction).balance, 2.5 ether);
        assertEq(auction.balanceOf(bidder1), 1 ether);
        assertEq(auction.balanceOf(bidder2), 1.5 ether);
        assertEq(auction.sealedBidOf(bidder1), sealedBid1);
        assertEq(auction.sealedBidOf(bidder2), sealedBid2);
    }

    function test_reveal() public {
        bytes32 sealedBid1 = genSealedBid(1 ether, bidder1nonce);
        bytes32 sealedBid2 = genSealedBid(1.5 ether, bidder2nonce);

        vm.prank(bidder1);
        auction.placeBid{value: 1 ether}(sealedBid1);
        vm.prank(bidder2);
        auction.placeBid{value: 1.5 ether}(sealedBid2);

        vm.warp(block.timestamp + 2 days + 1 seconds);

        vm.prank(bidder1);
        auction.reveal(1 ether, bidder1nonce);

        assertEq(auction.highBidder(), bidder1);
        assertEq(auction.highBid(), 1 ether);
        assertEq(auction.balanceOf(seller), 1 ether);
        assertEq(auction.balanceOf(bidder1), 0 ether);
        assertEq(auction.balanceOf(bidder2), 1.5 ether);

        vm.prank(bidder2);
        auction.reveal(1.5 ether, bidder2nonce);

        assertEq(auction.highBidder(), bidder2);
        assertEq(auction.highBid(), 1.5 ether);
        assertEq(auction.balanceOf(seller), 1.5 ether);
        assertEq(auction.balanceOf(bidder1), 1 ether);
        assertEq(auction.balanceOf(bidder2), 0 ether);
    }

    // TODO add tests to exercise obfuscated bids behavior

    function test_reveal_whenOutsideRevealingPeriod_shouldRevert() public {
        vm.expectRevert("SBA: can only reveal bid during reveal phase");

        vm.prank(bidder1);
        auction.reveal(1 ether, bidder1nonce);

        vm.warp(block.timestamp + 3 days);

        vm.expectRevert("SBA: can only reveal bid during reveal phase");

        vm.prank(bidder1);
        auction.reveal(1 ether, bidder1nonce);
    }

    function test_reveal_whenSealedBidDoesNotMatch_shouldRevert() public {
        bytes32 sealedBid = genSealedBid(1 ether, bidder1nonce);

        vm.prank(bidder1);
        auction.placeBid{value: 1 ether}(sealedBid);

        vm.warp(block.timestamp + 2 days + 1 seconds);

        vm.expectRevert("SBA: revealed bid does not match sealed bid");

        vm.prank(bidder1);
        auction.reveal(0.99 ether, sealedBid); // bad bid amount

        vm.expectRevert("SBA: revealed bid does not match sealed bid");

        vm.prank(bidder1);
        auction.reveal(1 ether, bytes32("been a bad bidder")); // bad nonce
    }

    function test_reveal_whenBidLessThanReservePrice_shouldRevert() public {
        bytes32 sealedBid = genSealedBid(0.9 ether, bidder1nonce);

        vm.prank(bidder1);
        auction.placeBid{value: 1 ether}(sealedBid);

        vm.warp(block.timestamp + 2 days + 1 seconds);

        vm.expectRevert("SBA: revealed bid is less than the reserve price");

        vm.prank(bidder1);
        auction.reveal(0.9 ether, bidder1nonce);
    }

    function test_reveal_whenSentValueLessThanBidAmount_shouldRevert() public {
        bytes32 sealedBid = genSealedBid(1.1 ether, bidder1nonce);

        vm.prank(bidder1);
        auction.placeBid{value: 1 ether}(sealedBid);

        vm.warp(block.timestamp + 2 days + 1 seconds);

        vm.expectRevert("SBA: sent value is less than the bid amount");

        vm.prank(bidder1);
        auction.reveal(1.1 ether, bidder1nonce);
    }

    // TODO withdraw
    // TODO claim
    // TODO failure to reveal sad paths

    /*//////////////////////////////////////////////////////////////
                        Helper Functions
    //////////////////////////////////////////////////////////////*/

    function genSealedBid(uint256 amount, bytes32 nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(amount, nonce));
    }
}

contract SealedBidAuction {
    //
    address public seller;

    address public tokenContract;
    uint256 public tokenId;
    uint256 public reservePrice;

    uint256 public endOfBidding;
    uint256 public endOfRevealing;

    mapping(address => uint256) public balanceOf;
    mapping(address => bytes32) public sealedBidOf;

    address public highBidder;
    uint256 public highBid;

    constructor(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _reservePrice,
        uint256 biddingPeriod,
        uint256 revealingPeriod
    ) {
        tokenContract = _tokenContract;
        tokenId = _tokenId;
        reservePrice = _reservePrice;

        endOfBidding = block.timestamp + biddingPeriod;
        endOfRevealing = endOfBidding + revealingPeriod;

        seller = msg.sender;
        highBidder = msg.sender; // initialized to seller, overwritten if at least 1 valid bid revealed
    }

    function placeBid(bytes32 sealedBid) public payable {
        require(block.timestamp < endOfBidding, "SBA: cannot place bid once bidding period is over");
        require(sealedBidOf[msg.sender] == 0, "SBA: cannot place more than one bid");
        require(msg.value >= reservePrice, "SBA: bid amount cannot be less than reserve price");

        sealedBidOf[msg.sender] = sealedBid;
        balanceOf[msg.sender] = msg.value;
    }

    function reveal(uint256 bidAmount, bytes32 nonce) public {
        require(block.timestamp >= endOfBidding && block.timestamp < endOfRevealing, "SBA: can only reveal bid during reveal phase");
        require(keccak256(abi.encodePacked(bidAmount, nonce)) == sealedBidOf[msg.sender], "SBA: revealed bid does not match sealed bid");
        require(bidAmount >= reservePrice, "SBA: revealed bid is less than the reserve price");
        require(bidAmount <= balanceOf[msg.sender], "SBA: sent value is less than the bid amount");

        if (bidAmount > highBid) {
            // return escrowed bid to previous high bidder
            balanceOf[seller] -= highBid;
            balanceOf[highBidder] += highBid;

            // store new high bid and bidder
            highBid = bidAmount;
            highBidder = msg.sender;

            // transfer new high bid from high bidder to seller balance
            balanceOf[highBidder] -= highBid;
            balanceOf[seller] += highBid;
        }
    }
}
