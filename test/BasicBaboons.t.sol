// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";

import {BasicBaboons} from "../src/BasicBaboons.sol";

contract BasicBaboonsTest is Test {
    //
    BasicBaboons babs;

    event Withdrawal(uint256 amount);
    event MaxSupplyUpdated(uint256 newSupply);
    event URIUpdated(string uri);
    event URIFrozen();
    event RoyaltyUpdated(address indexed receiver, uint96 royaltyPercentageInBips);

    uint16 INITIAL_MAX_SUPPLY = 1000;
    uint256 MINT_PRICE = 0.05 ether;

    uint8 TEAM_ALLOCATION = 20;
    address TEAM_MULTISIG = address(0xDEADBEEFCAFE);

    bytes32 PROVENANCE_HASH = keccak256("provenance hash"); // "052eb7eae2cf5b439673d338604e84923dd90f809b90538d19f4e78e45abc1cb"

    address[] ALLOWLIST = [
        address(0xF1),
        address(0xF2),
        address(0xF3),
        address(0xF4),
        address(0xF5),
        address(0xF6),
        address(0xF7),
        address(0xF8),
        address(0xF9),
        address(0xF10),
        address(0xF11),
        address(0xF12),
        address(0xF13),
        address(0xF14),
        address(0xF15)
    ];

    uint96 INITIAL_ROYALTY_PERCENTAGE_IN_BIPS = 500;
    uint96 MAX_ROYALTY_PERCENTAGE_IN_BIPS = 1000;

    function setUp() public {
        babs = new BasicBaboons(TEAM_MULTISIG, TEAM_ALLOCATION, ALLOWLIST, PROVENANCE_HASH);
    }

    function testIsERC721() public {
        assertEq(babs.name(), "Basic Baboons");
        assertEq(babs.symbol(), "BBB");
    }

    /*//////////////////////////////////////////////////////////////
                        Minting
    //////////////////////////////////////////////////////////////*/

    function testMint() public {
        babs.mint{value: MINT_PRICE}();
        babs.mint{value: MINT_PRICE}();
        hoax(address(0xBABE), 1 ether);
        babs.mint{value: MINT_PRICE}();

        assertEq(babs.balanceOf(address(this)), 2);
        assertEq(babs.ownerOf(TEAM_ALLOCATION + 1), address(this));
        assertEq(babs.ownerOf(TEAM_ALLOCATION + 2), address(this));
        assertEq(babs.balanceOf(address(0xBABE)), 1);
        assertEq(babs.ownerOf(TEAM_ALLOCATION + 3), address(0xBABE));
    }

    function testMintWhenNotEnoughEtherSentShouldRevert() public {
        vm.expectRevert("Mint price of 0.05 ETH not paid");
        babs.mint();

        vm.expectRevert("Mint price of 0.05 ETH not paid");
        babs.mint{value: MINT_PRICE - 0.01 ether}();

        vm.expectRevert("Mint price of 0.05 ETH not paid");
        babs.mint{value: MINT_PRICE + 0.01 ether}();
    }

    function testMintWhenMaxSupplyReachedShouldRevert() public {
        for (uint256 i = 0; i < INITIAL_MAX_SUPPLY - TEAM_ALLOCATION; i++) {
            babs.mint{value: MINT_PRICE}();
        }

        vm.expectRevert("Max supply already reached");
        babs.mint{value: MINT_PRICE}();
    }

    /*//////////////////////////////////////////////////////////////
                        Withdrawing
    //////////////////////////////////////////////////////////////*/

    function testWithdraw() public {
        assertEq(address(babs).balance, 0 ether);
        assertEq(TEAM_MULTISIG.balance, 0 ether);

        babs.mint{value: MINT_PRICE}();
        babs.mint{value: MINT_PRICE}();
        babs.mint{value: MINT_PRICE}();
        babs.mint{value: MINT_PRICE}();

        assertEq(address(babs).balance, MINT_PRICE * 4);

        vm.expectEmit(true, true, true, true);
        emit Withdrawal(MINT_PRICE * 4);

        vm.prank(TEAM_MULTISIG);
        babs.withdraw();

        assertEq(address(babs).balance, 0 ether);
        assertEq(TEAM_MULTISIG.balance, MINT_PRICE * 4);
    }

    /*//////////////////////////////////////////////////////////////
                        Managing Supply
    //////////////////////////////////////////////////////////////*/

    function testReduceSupply() public {
        assertEq(babs.maxSupply(), INITIAL_MAX_SUPPLY);

        vm.expectEmit(true, true, true, true);
        emit MaxSupplyUpdated(420);

        vm.prank(TEAM_MULTISIG);
        babs.reduceSupply(420);

        assertEq(babs.maxSupply(), 420);
    }

    function testReduceSupplyWhenGreaterThanOrEqualToPreviousMaxSupplyShouldRevert() public {
        vm.startPrank(TEAM_MULTISIG);
        
        // no revert
        babs.reduceSupply(999);
        assertEq(babs.maxSupply(), 999);

        vm.expectRevert("New supply must be < previous max supply and >= total supply");
        babs.reduceSupply(INITIAL_MAX_SUPPLY);
    }

    function testReduceSupplyWhenLessThanCurrentlyMintedShouldRevert() public {
        for (uint256 i = 0; i < 42; i++) {
            babs.mint{value: MINT_PRICE}();
        }

        vm.startPrank(TEAM_MULTISIG);

        // no revert
        babs.reduceSupply(42 + TEAM_ALLOCATION);
        assertEq(babs.maxSupply(), 42 + TEAM_ALLOCATION);

        vm.expectRevert("New supply must be < previous max supply and >= total supply");
        babs.reduceSupply(41 + TEAM_ALLOCATION);
    }

    /*//////////////////////////////////////////////////////////////
                        Team Allocation
    //////////////////////////////////////////////////////////////*/

    function testTeamAllocation() public {
        assertEq(babs.balanceOf(TEAM_MULTISIG), TEAM_ALLOCATION);
        for(uint256 i = 1; i < TEAM_ALLOCATION; i++) {
            assertEq(babs.ownerOf(i), TEAM_MULTISIG);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        Metadata and URI
    //////////////////////////////////////////////////////////////*/

    function testSetURI() public {
        vm.expectEmit(true, true, true, true);
        emit URIUpdated("https://newuri.xyz/");

        vm.prank(TEAM_MULTISIG);
        babs.setURI("https://newuri.xyz/");

        assertEq(babs.tokenURI(1), "https://newuri.xyz/1");
        assertEq(babs.tokenURI(2), "https://newuri.xyz/2");
        assertEq(babs.tokenURI(3), "https://newuri.xyz/3");
    }

    function testFreezeURI() public {
        vm.prank(TEAM_MULTISIG);
        babs.setURI("https://newuri.xyz/");

        vm.expectEmit(true, true, true, true);
        emit URIFrozen();

        vm.prank(TEAM_MULTISIG);
        babs.freezeURI();

        vm.expectRevert("URI is frozen and cannot be updated");

        vm.prank(TEAM_MULTISIG);
        babs.setURI("https://neweruri.xyz/");
    }

    function testFreezeURIWhenAlreadyFrozenShouldFail() public {
        vm.prank(TEAM_MULTISIG);
        babs.freezeURI();

        vm.expectRevert("URI already frozen");

        vm.prank(TEAM_MULTISIG);
        babs.freezeURI();
    }

    function testProvenanceHash() public {
        assertEq(babs.provenanceHash(), PROVENANCE_HASH);
    }

    // TODO add JSON tests

    /*//////////////////////////////////////////////////////////////
                        Access Control
    //////////////////////////////////////////////////////////////*/

    function test_Withdraw_WhenNotOwnerShouldFail() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(0xABCD)); // from random EOA
        babs.withdraw();
    }

    function test_ReduceSupply_WhenNotOwnerShouldFail() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(0xABCD)); // from random EOA
        babs.reduceSupply(999);
    }

    function test_SetURI_WhenNotOwnerShouldFail() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(0xABCD)); // from random EOA
        babs.setURI("hey there");
    }

    function test_FreezeURI_WhenNotOwnerShouldFail() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(0xABCD)); // from random EOA
        babs.freezeURI();
    }

    function test_SetNewRoyalty_WhenNotOwnerShouldFail() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(0xABCD)); // from random EOA
        babs.setNewRoyalty(MAX_ROYALTY_PERCENTAGE_IN_BIPS);
    }

    /*//////////////////////////////////////////////////////////////
                        Allowlist
    //////////////////////////////////////////////////////////////*/

    function test_MintAllowlist() public {
        for (uint256 i = 0; i < ALLOWLIST.length; i++) {
            address allowed = ALLOWLIST[i];

            assertEq(babs.allowlisted(allowed), true);
            assertEq(babs.balanceOf(allowed), 0);

            vm.prank(allowed);
            babs.mintAllowlist();

            assertEq(babs.allowlisted(allowed), false);
            assertEq(babs.balanceOf(allowed), 1);
        }
    }

    function test_MintAllowlist_WhenNotAllowlistedShouldFail() public {
        vm.expectRevert("Address not allowlisted");
        
        vm.prank(address(0xABCD)); // from random EOA
        babs.mintAllowlist();
    }

    /*//////////////////////////////////////////////////////////////
                        Royalties
    //////////////////////////////////////////////////////////////*/

    function testRoyalty(uint256 tokenId, uint256 salePrice) public {
        tokenId = bound(tokenId, 1, TEAM_ALLOCATION);
        salePrice = bound(salePrice, 0.01 ether, 100 ether);

        (address receiver, uint256 royaltyAmount) = babs.royaltyInfo(tokenId, salePrice);
        
        assertEq(receiver, TEAM_MULTISIG);
        assertEq(royaltyAmount, (salePrice * INITIAL_ROYALTY_PERCENTAGE_IN_BIPS) / 10_000);
    }

    function testSetNewRoyalty() public {
        vm.expectEmit(true, true, true, true);
        emit RoyaltyUpdated(TEAM_MULTISIG, MAX_ROYALTY_PERCENTAGE_IN_BIPS);

        vm.prank(TEAM_MULTISIG);
        babs.setNewRoyalty(MAX_ROYALTY_PERCENTAGE_IN_BIPS);

        (address receiver, uint256 royaltyAmount) = babs.royaltyInfo(1, 1 ether);

        assertEq(receiver, TEAM_MULTISIG);
        assertEq(royaltyAmount, (1 ether * MAX_ROYALTY_PERCENTAGE_IN_BIPS) / 10_000);
    }

    function testSetNewRoyaltyWhenGreaterThanMaxAllowedShouldFail() public {
        vm.expectRevert("New royalty percentage must not exceed 10%");
        
        vm.prank(TEAM_MULTISIG);
        babs.setNewRoyalty(MAX_ROYALTY_PERCENTAGE_IN_BIPS + 1);
    }

    // NOTE rn this is more a test of NFT transferring than royalty calculation
    // TODO study how Seaport and Zora v3 support EIP2981 and honor the royalty payment itself

    // function testRoyalty() public {
    //     vm.deal(address(0xA), 1 ether);
    //     vm.deal(address(0xB), 1 ether);
    //     vm.deal(TEAM_MULTISIG, 1 ether);
    //     uint256 contractBalance = address(babs).balance;

    //     uint256 tokenId = TEAM_ALLOCATION + 1;

    //     vm.startPrank(address(0xA));
    //     babs.mint{value: MINT_PRICE}();

    //     assertEq(address(babs).balance, contractBalance + MINT_PRICE);
    //     assertEq(address(0xA).balance, 1 ether - MINT_PRICE);

    //     assertEq(babs.ownerOf(tokenId), address(0xA));
    //     babs.safeTransferFrom(address(0xA), address(0xB), tokenId);
    //     assertEq(babs.ownerOf(tokenId), address(0xB));

    //     // assert what is returned from royaltyInfo
    // }    
}
