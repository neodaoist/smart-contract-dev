// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Cheater.sol";

contract CheaterTest is Test {
    //
    Cheater cheater;

    function setUp() public {
        cheater = new Cheater();
    }

    function testTellTruth_shouldRevertIfNot1337() public {
        vm.expectRevert("SOMETHING_WENT_WRONG");

        cheater.tellTruth(1);
    }

    function testTellTruth_shouldBeTrueIf1337() public {
        assertTrue(cheater.tellTruth(1337));
    }

    function testTellTruthWithError_shouldThrowIfNot1337() public {
        vm.expectRevert(Cheater.LieTold.selector);

        cheater.tellTruthWithError(1);
    }

    function testTellTruthWithError_shouldBeFalseIf1337() public {
        assertTrue(cheater.tellTruthWithError(1337));
    }

    function testTellTruthWithErrorWithParams_shouldThrowIfNot1337() public {
        vm.expectRevert(abi.encodeWithSelector(Cheater.LieToldWithParams.selector, 1));

        cheater.tellTruthWithErrorWithParams(1);
    }

    function testTellTruthWithErrorWithParams_shouldBeTrueIf1337() public {
        assertTrue(cheater.tellTruthWithErrorWithParams(1337));
    }

    // how to assert the specific require message ?
    function testFailTellTruthWithRequire_shouldThrowIfNot1337() public {
        cheater.tellTruthWithRequire(1);
    }
}
