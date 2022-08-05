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

    uint16 INITIAL_MAX_SUPPLY = 1000;

    uint8 TEAM_ALLOCATION = 20;
    address TEAM_MULTISIG = address(0xDEADBEEFCAFE);

    function setUp() public {
        babs = new BasicBaboons(TEAM_MULTISIG, TEAM_ALLOCATION);
    }

    function testIsERC721() public {
        assertEq(babs.name(), "Basic Baboons");
        assertEq(babs.symbol(), "BBB");
    }

    /*//////////////////////////////////////////////////////////////
                        Minting
    //////////////////////////////////////////////////////////////*/

    function testMint() public {
        babs.mint{value: 0.05 ether}();
        babs.mint{value: 0.05 ether}();
        hoax(address(0xBABE), 1 ether);
        babs.mint{value: 0.05 ether}();

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
        babs.mint{value: 0.04 ether}();

        vm.expectRevert("Mint price of 0.05 ETH not paid");
        babs.mint{value: 0.06 ether}();
    }

    function testMintWhenMaxSupplyReachedShouldRevert() public {
        for (uint256 i = 0; i < INITIAL_MAX_SUPPLY - TEAM_ALLOCATION; i++) {
            babs.mint{value: 0.05 ether}();
        }

        vm.expectRevert("Max supply already reached");
        babs.mint{value: 0.05 ether}();
    }

    /*//////////////////////////////////////////////////////////////
                        Withdrawing
    //////////////////////////////////////////////////////////////*/

    function testWithdraw() public {
        assertEq(address(babs).balance, 0 ether);
        assertEq(address(0xBABE).balance, 0 ether);

        babs.mint{value: 0.05 ether}();
        babs.mint{value: 0.05 ether}();
        babs.mint{value: 0.05 ether}();
        babs.mint{value: 0.05 ether}();

        assertEq(address(babs).balance, 0.2 ether);

        vm.expectEmit(true, true, true, true);
        emit Withdrawal(0.2 ether);

        vm.prank(address(0xBABE));
        babs.withdraw();

        assertEq(address(babs).balance, 0 ether);
        assertEq(address(0xBABE).balance, 0.2 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        Managing Supply
    //////////////////////////////////////////////////////////////*/

    function testReduceSupply() public {
        assertEq(babs.maxSupply(), INITIAL_MAX_SUPPLY);

        vm.expectEmit(true, true, true, true);
        emit MaxSupplyUpdated(420);

        babs.reduceSupply(420);

        assertEq(babs.maxSupply(), 420);
    }

    function testReduceSupplyWhenMoreThanOrEqualToPreviousMaxSupplyShouldRevert() public {
        // no revert
        babs.reduceSupply(999);
        assertEq(babs.maxSupply(), 999);

        vm.expectRevert("New supply must be < previous max supply and >= total supply");
        babs.reduceSupply(INITIAL_MAX_SUPPLY);
    }

    function testReduceSupplyWhenLessThanCurrentlyMintedShouldRevert() public {
        for (uint256 i = 0; i < 42; i++) {
            babs.mint{value: 0.05 ether}();
        }

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

        babs.setURI("https://newuri.xyz/");

        assertEq(babs.tokenURI(1), "https://newuri.xyz/1");
        assertEq(babs.tokenURI(2), "https://newuri.xyz/2");
        assertEq(babs.tokenURI(3), "https://newuri.xyz/3");
    }

    function testFreezeURI() public {
        babs.setURI("https://newuri.xyz/");

        vm.expectEmit(true, true, true, true);
        emit URIFrozen();

        babs.freezeURI();

        vm.expectRevert("URI is frozen and cannot be updated");

        babs.setURI("https://neweruri.xyz/");
    }

    function testFreezeURIWhenAlreadyFrozenShouldFail() public {
        babs.freezeURI();

        vm.expectRevert("URI already frozen");

        babs.freezeURI();
    }
}
