// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract PropertyFunTest is Test {
    //
    function testFuzz(uint8 i) public {
        assertTrue(i < 256);
    }

    function proveNah(uint8 i) public {
        assert(i < 256);

        // do other stuff
        emit log_named_uint("The number is: ", i);
    }
}
