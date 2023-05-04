// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract GasTest is Test {
    //
    error ShortError();

    error LongErrorrrrrrrrrrrrrrrrrrrrrrrrLongErrorrrrrrrrrrrrrrrrrrrrrrrr();

    function testFail_ShortError() public {
        revert ShortError();
    }

    function testFail_LongError() public {
        revert LongErrorrrrrrrrrrrrrrrrrrrrrrrrLongErrorrrrrrrrrrrrrrrrrrrrrrrr();
    }

    function testFail_ShortRevertString() public {
        require(false, "Short String");
    }

    function testFail_LongRevertString() public {
        require(false, "LongggggggggggggggggggggggggggggLonggggggggggggggggggggggggggggg");
    }
}
