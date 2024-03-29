// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract Reverter {
    //
    function shouldRevert(bool shouldIt) public {
        require(!shouldIt, "REVERT");
    }
}

contract ReverterTest is Test {
    Reverter reverter = new Reverter();

    function testShouldNotRevert() public {
        reverter.shouldRevert(false);
    }

    function testShouldRevert() public {
        vm.expectRevert("REVERT");
        reverter.shouldRevert(true);
    }
}
