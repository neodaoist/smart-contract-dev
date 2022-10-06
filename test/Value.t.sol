// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ValueSender} from "../src/ValueSender.sol";

contract ValueTest is Test {
    //
    ValueSender value;

    function setUp() public {
        value = new ValueSender();
    }

    function testSendValue() public {
        address from = address(0xBABE);
        address to = address(0xABCD);

        vm.deal(from, 1 ether);
        vm.deal(to, 1 ether);
        assertEq(address(value).balance, 0 ether);

        assertEq(value.balanceOf(to), 0);

        vm.prank(from);
        uint256 tokenID = value.mint{value: 0.1 ether}(to, "happy birthday!");

        assertEq(from.balance, 0.9 ether);
        assertEq(to.balance, 1.1 ether);
        assertEq(address(value).balance, 0 ether);

        assertEq(value.balanceOf(to), 1);
        assertEq(value.tokenURI(tokenID), "happy birthday!");
    }
}
