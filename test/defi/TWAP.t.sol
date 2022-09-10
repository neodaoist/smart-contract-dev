// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract TWAPTest is Test {
    //
    TWAP twap;

    function setUp() public {
        vm.warp(2_000_000_000); // ~2033-05-18
        twap = new TWAP();
    }

    function test_reportPrice() public {
        skip(7 seconds);
        vm.roll(1);
        twap.reportPrice(42);

        skip(7 seconds);
        vm.roll(2);
        twap.reportPrice(44);

        assertEq(twap.cumulativePrice(), (42 * 7) + (44 * 7));
    }

    function test_reportPrice(
        uint256 t1,
        uint256 t2,
        uint256 t3,
        uint256 t4,
        uint256 t5,
        uint256 p1,
        uint256 p2,
        uint256 p3,
        uint256 p4,
        uint256 p5
    )
        public
    {
        t1 = bound(t1, 5 seconds, 15 seconds);
        t2 = bound(t2, 5 seconds, 15 seconds);
        t3 = bound(t3, 5 seconds, 15 seconds);
        t4 = bound(t4, 5 seconds, 15 seconds);
        t5 = bound(t5, 5 seconds, 15 seconds);
        p1 = bound(p1, 1, 100);
        p2 = bound(p2, 1, 100);
        p3 = bound(p3, 1, 100);
        p4 = bound(p4, 1, 100);
        p5 = bound(p5, 1, 100);

        vm.roll(1);
        skip(t1);
        twap.reportPrice(p1);

        vm.roll(2);
        skip(t2);
        twap.reportPrice(p2);

        vm.roll(3);
        skip(t3);
        twap.reportPrice(p3);

        vm.roll(4);
        skip(t4);
        twap.reportPrice(p4);

        vm.roll(5);
        skip(t5);
        twap.reportPrice(p5);

        assertEq(twap.cumulativePrice(), (p1 * t1) + (p2 * t2) + (p3 * t3) + (p4 * t4) + (p5 * t5));
    }

    function test_calculateHourlyTWAP() public {
        uint256 singleP;
        uint256 singleT;
        uint256 cumulativeP;
        uint256[] memory prices = new uint256[](240);
        uint256[] memory times = new uint256[](240);

        for (uint256 i = 0; i < 240; i++) {
            singleP = block.timestamp % 100; // pseudorandom
            singleT = block.timestamp % 15; // pseudorandom
            prices[i] = singleP;
            times[i] = singleT;

            skip(singleT);
            vm.roll(i);
            twap.reportPrice(singleP);
        }

        for (uint256 j = 0; j < prices.length; j++) {
            cumulativeP += (prices[j] * times[j]);
        }

        // check cumulative price
        assertEq(twap.cumulativePrice(), cumulativeP);

        // log hourly TWAP
        uint256 hourlyTWAP = twap.cumulativePrice() / (block.timestamp - 2_000_000_000);
        emit log_uint(hourlyTWAP);

        // TODO make times and prices more random
        // TODO save cumulativePrice at start of test
        // TODO separate TWAP Calculation from Price Oracle
    }
}

contract TWAP {
    //
    uint256 public cumulativePrice;
    uint256 private lastBlockTimestamp;

    constructor() {
        lastBlockTimestamp = block.timestamp;
    }

    /// @dev For now assumes only called once per block
    function reportPrice(uint256 _price) public {
        uint256 secondsSinceLastBlock = block.timestamp - lastBlockTimestamp;
        cumulativePrice += (_price * secondsSinceLastBlock);
        lastBlockTimestamp = block.timestamp;
    }
}
