// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

contract BytesTest is Test {
    //
    function testString() public {
        string memory abcd = "abcd";
    }

    function testFixedSizeByteArray() public {
        bytes32 b32;
    }

    // function testDynamicSizeByteArrays() public {
    //     bytes storage b; // i.e., byte[]
    //     assertEq(b.length, 0);

    //     b.push(1);
    //     // assembly {
    //     //     b := push(b, 1)
    //     // }

    //     assertEq(b.length, 1);
    // }
}
