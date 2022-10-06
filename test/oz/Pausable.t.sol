// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Pausable} from "openzeppelin/contracts/security/Pausable.sol";

// event Paused
// event Unpaused

// modifier WhenPaused
// modifier WhenNotPaused

// function paused() view

// function _pause()
// function _unpause()

contract PausableContract is Pausable {
    //
    function handleBusiness() public whenNotPaused {
        //
    }

    function handlePausedBusiness() public whenPaused {
        //
    }

    function pause() public {
        _pause();
    }

    function unpause() public {
        _unpause();
    }
}

contract PausableTest is Test {
    //
    PausableContract pausable;

    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        pausable = new PausableContract();
    }

    function testPause() public {
        assertFalse(pausable.paused());

        vm.expectEmit(true, true, true, true);
        emit Paused(address(this));

        pausable.pause();

        assertTrue(pausable.paused());
    }

    function testUnpause() public {
        pausable.pause();

        assertTrue(pausable.paused());

        vm.expectEmit(true, true, true, true);
        emit Unpaused(address(this));

        pausable.unpause();

        assertFalse(pausable.paused());
    }

    function testWhenNotPaused() public {
        pausable.handleBusiness();

        pausable.pause();

        vm.expectRevert("Pausable: paused");
        pausable.handleBusiness();
    }

    function testWhenPaused() public {
        vm.expectRevert("Pausable: not paused");

        pausable.handlePausedBusiness();

        pausable.pause();

        // no revert
        pausable.handlePausedBusiness();
    }

    function testMuchPausingAndUnpausing() public {
        uint8 i;

        for (i = 0; i < 255; i++) {
            assertFalse(pausable.paused());
            pausable.pause();
            assertTrue(pausable.paused());
            pausable.unpause();
        }
    }
}
