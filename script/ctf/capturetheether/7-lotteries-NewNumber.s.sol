// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract GuessTheNewNumberChallengeScript is Script {
    //
    function run() public {
        vm.broadcast();
        AttackerContract attacker = AttackerContract(0x309540f8b1547a197F00f806B4b50C59B0A907d7);
        attacker.guess{value: 1 ether}();
    }
}

interface AttackerContract {
    function guess() external payable;
}
