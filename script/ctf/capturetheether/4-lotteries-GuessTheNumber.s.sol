// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract GuessTheNumberScript is Script {
    //

    function run() public {
        vm.broadcast();
        GuessTheNumberChallenge challenge = GuessTheNumberChallenge(0x824026FB0735b7fCa0E02C24C1A466D2210A7be4);
        challenge.guess{value: 1 ether}(42);
    }
}

interface GuessTheNumberChallenge {
    function guess(uint8 n) external payable;
}
