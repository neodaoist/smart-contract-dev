// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// inspired by
contract XYZTest is Test {
    //
    XYZ xyz;

    function setUp() public {
        xyz = new XYZ();
    }

    function test() public {
        assertTrue(true);
    }
}

contract XYZ {
//
}
