// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract TrivialTest is Test {
    //

    Trivial trivial;

    function setUp() public {
        trivial = new Trivial();
    }

    function test_getValue() public {
        assertEq(trivial.getValue(), 77);
    }
}

contract Trivial {
    //
    function getValue() public pure returns (uint256) {
        return 77;
    }
}
