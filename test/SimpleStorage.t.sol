// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test} from "forge-std/Test.sol";
import {SimpleStorage3} from "../src/SimpleStorage.sol";

contract SimpleStorage3Test is Test {
    //
    SimpleStorage3 ss;

    address user = address(0xCAFE);

    event NumberSet(address indexed setter, uint8 newNumber);

    function setUp() public {
        ss = new SimpleStorage3();
    }

    function test_set() public {
        vm.expectEmit(true, true, true, true);
        emit NumberSet(user, 1);

        vm.prank(user);
        ss.set(1);

        assertEq(ss.get(), 1);
    }

    function test_setMultiple() public {
        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit NumberSet(user, 1);

        ss.set(1);

        assertEq(ss.get(), 1);

        vm.expectEmit(true, true, true, true);
        emit NumberSet(user, 2);

        ss.set(2);
        
        assertEq(ss.get(), 2);

        vm.expectEmit(true, true, true, true);
        emit NumberSet(user, 3);
        vm.expectEmit(true, true, true, true);
        emit NumberSet(user, 1);

        ss.set(3);
        ss.set(1);

        assertEq(ss.get(), 1);
    }
}
