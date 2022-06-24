// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    //
    SimpleStorage ss;

    function setUp() public {
        ss = new SimpleStorage();
    }

    function testSimpleStorage() public {
        ss.set(123);

        assertEq(ss.get(), 123);
    }
}
