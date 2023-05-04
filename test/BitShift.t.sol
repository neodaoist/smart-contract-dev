// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

contract BitShiftTest is Test {
    //
    function testShift() public {
        uint16 a = 100;
        uint16 by1 = a << 1;

        // 0000 0000 0110 0100

        // 0000 0000 0011 0010
        // 0000 0000 1100 1000

        emit log_uint(a >> 6);
        emit log_string("~~~");
        emit log_uint(by1);
        emit log_uint(a << 2);
        emit log_uint(a << 3);
        emit log_uint(a << 4);
        emit log_uint(a << 5);
        emit log_uint(a << 6);
        emit log_uint(a << 7);
        emit log_uint(a << 8);
        emit log_uint(a << 9);
        emit log_uint(a << 10);
        emit log_uint(a << 11);
        emit log_uint(a << 12);
        emit log_uint(a << 13);
        emit log_uint(a << 14);
        emit log_uint(a << 15);
        emit log_uint(a << 16);
        emit log_uint(a << 17);
        emit log_string("~~~");
        emit log_uint(a <<= 1);
        emit log_uint(a);
        emit log_string("~~~");
        emit log_uint(a >>= 2);
        emit log_uint(a);
    }
}
