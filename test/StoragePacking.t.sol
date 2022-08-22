// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Test.sol";

// forge inspect TwoSlots storage
// forge inspect ThreeSlots storage
// forge test --gas-report --match-contract StoragePackingTest

contract TwoSlots {
    //
    uint128 public first;
    uint128 public second;
    uint256 public third;

    // constructor () public {
    //     first = 123;
    //     second = 456;
    //     third = 789;
    // }

    function setFirst(uint128 _first) public {
        first = _first;
    }

    function setSecond(uint128 _second) public {
        second = _second;
    }

    function setThird(uint128 _third) public {
        third = _third;
    }
}

contract ThreeSlots {
    //
    uint128 public first;
    uint256 public second;
    uint128 public third;

    // constructor () public {
    //     first = 123;
    //     second = 456;
    //     third = 789;
    // }

    function setFirst(uint128 _first) public {
        first = _first;
    }

    function setSecond(uint128 _second) public {
        second = _second;
    }

    function setThird(uint128 _third) public {
        third = _third;
    }
}

contract StoragePackingTest is Test {
    //
    TwoSlots twoSlots;
    ThreeSlots threeSlots;

    function setUp() public {
        twoSlots = new TwoSlots();
        threeSlots = new ThreeSlots();
    }

    function testTwoSlots() public {
        assertEq(twoSlots.first(), 0);
        assertEq(twoSlots.second(), 0);
        assertEq(twoSlots.third(), 0);

        twoSlots.setFirst(1);
        twoSlots.setSecond(2);
        twoSlots.setThird(3);

        assertEq(twoSlots.first(), 1);
        assertEq(twoSlots.second(), 2);
        assertEq(twoSlots.third(), 3);
    }

    function testThreeSlots() public {
        assertEq(threeSlots.first(), 0);
        assertEq(threeSlots.second(), 0);
        assertEq(threeSlots.third(), 0);

        threeSlots.setFirst(1);
        threeSlots.setSecond(2);
        threeSlots.setThird(3);

        assertEq(threeSlots.first(), 1);
        assertEq(threeSlots.second(), 2);
        assertEq(threeSlots.third(), 3);
    }
}
