// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract CounterTest is Test {
    //
    Counter counter;

    uint256 FIRST = 77;

    // function setUp() public {
    //     counter = new Counter(FIRST);
    // }

    function test_initial(uint256 _count) public {
        counter = new Counter(_count);
        assertEq(counter.count(), _count);
    }

    function test_increment() public {
        counter = new Counter(FIRST);
        assertEq(counter.count(), FIRST);

        for (uint256 i = 1; i < 101; i++) {
            counter.increment();
            assertEq(counter.count(), FIRST + i);            
        }
    }
}

contract Counter {
    //
    uint256 public count;

    constructor (uint256 _count) {
        count = _count;
    }
    
    function increment() public {
        count += 1;
    }
}
