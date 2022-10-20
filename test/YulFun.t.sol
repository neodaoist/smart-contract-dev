// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

contract FunWithYulTest is Test {
    //
    FunWithYul yul;

    function setUp() public {
        yul = new FunWithYul();
    }

    // function test_slot() public {
    //     assertEq(yul.aa(), 0);
    //     assertEq(yul.bb(), 1);
    //     assertEq(yul.cc(), 2);
    // }

    function test_slot_whenMultipleVarsLessThanOneWord() public {
        assertEq(yul.slot0A(), 0);
        assertEq(yul.slot0B(), 0);
    }

    function test_multipleSlots() public {
        assertEq(yul.slot1A(), 1);
        assertEq(yul.slot1B(), 1);
        assertEq(yul.slot1C1(), 1);
        assertEq(yul.slot1C2(), 1);
        assertEq(yul.slot1C3(), 1);
        assertEq(yul.slot1C4(), 1);
        assertEq(yul.slot1C5(), 1);
        assertEq(yul.slot1C6(), 1);
        assertEq(yul.slot1C7(), 1);
        assertEq(yul.slot1C8(), 1);
        assertEq(yul.slot2A(), 2);
        assertEq(yul.slot3A(), 3);
    }
}

contract FunWithYul {
    //
    address private zeroA = address(0xCAFE);
    uint96 private zeroB = 123;
    uint96 private oneA;
    uint96 private oneB;
    bool private oneC1;
    bool private oneC2;
    bool private oneC3;
    bool private oneC4;
    bool private oneC5;
    bool private oneC6;
    bool private oneC7;
    bool private oneC8;
    bytes32 private twoA;
    bytes32 private threeA;

    uint256 private a;
    uint256 private b;
    uint256 private c;

    function slot0A() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := zeroA.slot
        }
        return slot;
    }

    function slot0B() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := zeroB.slot
        }
        return slot;
    }

    function slot1A() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := oneA.slot
        }
        return slot;
    }

    function slot1B() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := oneB.slot
        }
        return slot;
    }

    function slot1C1() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := oneC1.slot
        }
        return slot;
    }

    function slot1C2() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := oneC2.slot
        }
        return slot;
    }

    function slot1C3() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := oneC3.slot
        }
        return slot;
    }

    function slot1C4() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := oneC4.slot
        }
        return slot;
    }

    function slot1C5() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := oneC5.slot
        }
        return slot;
    }

    function slot1C6() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := oneC6.slot
        }
        return slot;
    }

    function slot1C7() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := oneC7.slot
        }
        return slot;
    }

    function slot1C8() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := oneC8.slot
        }
        return slot;
    }

    function slot2A() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := twoA.slot
        }
        return slot;
    }

    function slot3A() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := threeA.slot
        }
        return slot;
    }

    /*//////////////////////////////////////////////////////////////
                        XYZ
    //////////////////////////////////////////////////////////////*/

    function aa() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := a.slot
        }
        return slot;
    }

    function bb() external pure returns (uint256) {
        uint256 slot;
        uint256 bbb = 1;
        assembly {
            slot := add(a.slot, bbb)
        }
        return slot;
    }

    function cc() external pure returns (uint256) {
        uint256 slot;
        assembly {
            slot := c.slot
        }
        return slot;
    }
}
