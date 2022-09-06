// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract StateTest is Test {
    //
    State state;

    uint256 THE_VALUE = 42;

    function setUp() public {
        state = new State(THE_VALUE);
    }

    function test_getValue() public {
        assertEq(state.getValue(), THE_VALUE);
    }
}

contract State {
    //
    uint256 private state;

    constructor (uint256 _state) {
        state = _state;
    }

    function getValue() public view returns (uint256) {
        return state;
    }
}
