// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract MathTest is Test {
    //

    // (500*.08*(11/12))+(500*.08*(10/12))+(500*.08*(9/12))+(500*.08*(8/12))+(500*.08*(7/12))+(500*.08*(6/12))+(500*.08*(5/12))+(500*.08*(4/12))+(500*.08*(3/12))+(500*.08*(2/12))+(500*.08*(1/12))
    function test_Sum() public {
        uint256 price = 500_0000;
        uint256 interestInBps = 800;
        uint256[] memory term = new uint256[](11);
        term[0] = 11;
        term[1] = 10;
        term[2] = 9;
        term[3] = 8;
        term[4] = 7;
        term[5] = 6;
        term[6] = 5;
        term[7] = 4;
        term[8] = 3;
        term[9] = 2;
        term[10] = 1;

        uint256 sum = 0;
        for (uint256 i = 0; i < term.length; i++) {
            sum += ((price * interestInBps) / 10_000 * term[i]) / 12;
        }

        assertApproxEqAbs(sum, 220_0000, 10); // +/- 10 bps of precision
    }

    // calculates x*y/z
    // rounds result down
    // throws if z is zero or result overflows uint256
    function test_MulDiv() public {
        uint256 x = 1_337;
        uint256 y = 420_690_069;
        uint256 z = 7;

        assertEq(mulDiv(x, y, z), 80_351_803_179);
        // assertEq(mulDivBetter(x, y, z), 80_351_803_179);
    }

    function mulDivBetter(uint256 x, uint256 y, uint256 z) public pure returns (uint256) {
        // x = a * z + b
        uint256 a = x / z;
        uint256 b = x % z;
        // y = c * z + d
        uint256 c = y / z;
        uint256 d = y % z;

        return a * b * z + a * d + b * c + b * d / z;
    }

    function mulDiv(uint256 x, uint256 y, uint256 z) public pure returns (uint256) {
        return x * y / z;
    }

    function test_Shift() public {
        emit log_uint(42_069 >> 1);
    }

    // function test_CalculateForwardPrice_PhysicalCommodities() public {
    //     // F = C * (1 + R * t) + (s * t) + (i * t)
    //     // 3-month Forward price = $77.40
    //     // Interest rate = 8%
    //     // Annual storage costs = $3.00
    //     // Annual insurance costs = $0.60
    //     // What should be the cash price C?

    //     // (77.40)-((3+0.06)*3/12)/(1.08*3/12)
    //     uint256 cashPrice =
    //     assertEq(cashPrice, 75_00);
    // }

    // function test_Overflow() public {
    //     unchecked {
    //         int256 i = -2 ** 127 / -1;
    //     }
    // }
}
