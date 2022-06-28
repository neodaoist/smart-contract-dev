// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";

import {ERC721Contract} from "../../src/oz/ERC721Contract.sol";

contract ERC721Test is Test {
    //
    ERC721Contract token;

    address owner = address(0xBABE);
    address rando = address(0xABCD);
    address to = address(0xCAFE);
    address approved = address(0xDEAD);
    address operator = address(0xBEEF);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setUp() public {
        token = new ERC721Contract();
    }

    function testInvariantMetadata() public {
        assertEq(token.name(), "Epique NFT");
        assertEq(token.symbol(), "EPIQUE");
    }

    /*//////////////////////////////////////////////////////////////
                        Test Helpers
    //////////////////////////////////////////////////////////////*/

    function givenMintedTokens() internal {
        token.mint(owner, 123);
        token.mint(owner, 456);
    }

    function andSetupApprovals() internal {
        vm.startPrank(owner);
        token.approve(approved, 123);
        token.setApprovalForAll(operator, true);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        Based on OZ JS test suite
    //////////////////////////////////////////////////////////////*/

    // TODO add ERC165 and ERC721 interface tests

    function testBalanceOf_whenAddressOwnsTokens_thenReturnCorrectAmountOfTokens() public {
        givenMintedTokens();

        assertEq(token.balanceOf(owner), 2);
    }

    function testBalanceOf_whenAddressDoesNotOwnTokens_thenReturn0() public {
        givenMintedTokens();

        assertEq(token.balanceOf(rando), 0);
    }

    function testBalanceOf_whenQueryingZeroAddress_thenThrow() public {
        givenMintedTokens();

        vm.expectRevert("ERC721: address zero is not a valid owner");

        token.balanceOf(address(0));
    }

    function testOwnerOf_whenTokenExists_thenReturnCorrectOwner() public {
        givenMintedTokens();

        assertEq(token.ownerOf(123), owner);
    }

    function testOwnerOf_whenTokenDoesNotExist_thenThrow() public {
        givenMintedTokens();

        vm.expectRevert("ERC721: invalid token ID");

        token.ownerOf(13);
    }

    function testTransferFrom_whenTokenIsTransferred_thenUpdateOwner() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.prank(approved);
        token.transferFrom(owner, to, 123);

        assertEq(token.ownerOf(123), to);
    }

    function testTransferFrom_whenTokenIsTransferred_thenEmitTransfer() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, to, 123);

        vm.prank(approved);
        token.transferFrom(owner, to, 123);
    }

    function testTransferFrom_whenTokenIsTransferred_thenCleanApproval() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.prank(approved);
        token.transferFrom(owner, to, 123);

        assertEq(token.getApproved(123), address(0));
    }

    function testTransferFrom_whenTokenIsTransferred_thenEmitApprovalOfZeroAddress() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.expectEmit(true, true, true, true);
        emit Approval(owner, address(0), 123);

        vm.prank(approved);
        token.transferFrom(owner, to, 123);
    }

    function testTransferFrom_whenTokenIsTransferred_thenUpdateBalances() public {
        givenMintedTokens();
        andSetupApprovals();

        // to improve test readability
        assertEq(token.balanceOf(owner), 2);
        assertEq(token.balanceOf(to), 0);

        vm.prank(approved);
        token.transferFrom(owner, to, 123);

        assertEq(token.balanceOf(owner), 1);
        assertEq(token.balanceOf(to), 1);
    }

    function testTransferFrom_whenTokenIsTransferred_thenUpdateOwners() public {
        givenMintedTokens();
        andSetupApprovals();

        // to improve test readability
        assertEq(token.ownerOf(123), owner);

        vm.prank(approved);
        token.transferFrom(owner, to, 123);

        assertEq(token.ownerOf(123), to);
    }

    /*//////////////////////////////////////////////////////////////
                        Based on OZ functions, bottoms-up
    //////////////////////////////////////////////////////////////*/

    // supportsInterface

    // balanceOf

    // ownerOf

    // tokenURI

    // approve

    // getApproved

    // setApprovalForAll

    // isApprovedForAll

    // transferFrom

    // safeTransferFrom

    // safeTransferFrom (with data)

    // INTERNAL

    // _safeTransfer

    // _exists

    // _isApprovedOrOwner

    // _safeMint

    // _safeMint (with data)

    // _mint

    // _burn

    // _transfer

    // _approve

    // _setApprovalForAll

    // _requireMinted

    // _checkOnERC721Received

    // _beforeTokenTransfer

    // _afterTokenTransfer
}
