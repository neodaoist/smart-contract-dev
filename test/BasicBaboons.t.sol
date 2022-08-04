// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";

import {BasicBaboons} from "../src/BasicBaboons.sol";

contract BasicBaboonsTest is Test {
    //
    BasicBaboons babs;

    event MaxSupplyUpdated(uint256 newSupply);

    function setUp() public {
        babs = new BasicBaboons();
    }

    function testIsERC721() public {
        assertEq(babs.name(), "Basic Baboons");
        assertEq(babs.symbol(), "BBB");
    }

    function testMint() public {
        babs.mint{value: 0.05 ether}();
        babs.mint{value: 0.05 ether}();
        hoax(address(0xBABE), 1 ether);
        babs.mint{value: 0.05 ether}();

        assertEq(babs.balanceOf(address(this)), 2);
        assertEq(babs.ownerOf(1), address(this));
        assertEq(babs.ownerOf(2), address(this));
        assertEq(babs.balanceOf(address(0xBABE)), 1);
        assertEq(babs.ownerOf(3), address(0xBABE));
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
        for (uint256 i = 0; i < 1000; i++) {
            babs.mint{value: 0.05 ether}();
        }

        vm.expectRevert("Max supply already reached");
        babs.mint{value: 0.05 ether}();
    }

    function testReduceSupply() public {
        assertEq(babs.maxSupply(), 1000);

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
        babs.reduceSupply(1000);
    }

    function testReduceSupplyWhenLessThanCurrentlyMintedShouldRevert() public {
        for (uint256 i = 0; i < 42; i++) {
            babs.mint{value: 0.05 ether}();
        }

        // no revert
        babs.reduceSupply(42);
        assertEq(babs.maxSupply(), 42);

        vm.expectRevert("New supply must be < previous max supply and >= total supply");
        babs.reduceSupply(41);
    }
}
