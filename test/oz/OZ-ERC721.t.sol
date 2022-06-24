// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";

import {ERC721Contract} from "../../src/oz/ERC721Contract.sol";

contract ERC721Test is Test {
    //
    ERC721Contract private epique;

    function setUp() public {
        epique = new ERC721Contract();
    }

    function testInvariantMetadata() public {
        assertEq(epique.name(), "Epique NFT");
        assertEq(epique.symbol(), "EPIQUE");
    }

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
