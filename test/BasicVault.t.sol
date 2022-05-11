// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "forge-std/Test.sol";
import "../src/BasicVault.sol";

contract BasicVaultTest is Test {

    BasicVault vault;

    constructor() {
        vault = new BasicVault(new LeetToken());
    }

    function testUserCannotWithdrawExcessOfDeposit() public {
        vm.prank(address(0xBABE));
        vm.expectRevert(stdError.arithmeticError);

        vault.withdraw(100*10**18);
    }
}
