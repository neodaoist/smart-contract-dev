// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

import "../../src/solidity-by-example-take-2/HelloWorld.sol";

contract HelloWorldTest is Test {
    //
    HelloWorld private hello;

    function setUp() public {
        hello = new HelloWorld();
    }

    // function testSetSecond() public {
    //     hello.setSecond("Goodbye World");
    // }

    // function testGetSecond() public {
    //     hello.getSecond();
    // }

    function testGetSecondCold() public {
        hello.getSecond();
    }

    function testFirst() public {
        assertEq(hello.getFirst(), 123);

        hello.setFirst(321);

        assertEq(hello.getFirst(), 321);
    }

    function testSecond() public {
        assertEq(hello.getSecond(), 1);

        hello.setSecond(456);

        assertEq(hello.getSecond(), 456);
    }

    function testAll() public {
        assertEq(hello.getFirst(), 123);
        assertEq(hello.getSecond(), 1);

        hello.setFirst(321);
        hello.setSecond(456);

        assertEq(hello.getFirst(), 321);
        assertEq(hello.getSecond(), 456);
    }
}
