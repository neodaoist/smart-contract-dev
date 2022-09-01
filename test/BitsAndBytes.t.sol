// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Test.sol";

contract BitsAndBytesTest is Test {
    //

    function testAddress() public {
        address one = address(0x1);
        assertEq(one, 0x0000000000000000000000000000000000000001);

        address two = address(0x12);
        assertEq(two, 0x0000000000000000000000000000000000000012);

        address more = address(0x1234567890123456789012345678901234567890);
        assertEq(more, 0x1234567890123456789012345678901234567890);
    }

    function testString() public {
        // string memory str = "123456789A123456789B123456789C123456789D123456789E123456789F123456789G123456789H";
        // string memory str = "hello"; // 0x68656c6c6f
        // string memory str = "h"; // 0x68
        // string memory str = unicode"¥"; // 0xc2a5
        string memory str = unicode"🙂"; // 0xf09f9982
        
        // emit log_bytes(bytes(str));
        assertEq(bytes(str), bytes(hex"f09f9982"));
    }

    function testAbiEncodePacked() public {
        uint8 num = 255;
        string memory str = "hello";
        bytes1 byt = bytes1(0x42);

        assertEq(abi.encodePacked(num), bytes(hex"ff"));
        assertEq(abi.encodePacked(num, str), bytes(hex"ff68656c6c6f"));
        bytes memory packed = abi.encodePacked(num, str, byt);
        assertEq(packed, bytes(hex"ff68656c6c6f42"));

        emit log_bytes(packed);
        emit log_bytes32(keccak256(packed));
    }
}
