// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract GuessTheRandomNumberChallengeScript is Script {
    //
    uint256 targetBlockNumber = 12935261;
    uint256 targetTimestamp = 1662421644; // Sep-05-2022 11:47:24 PM +UTC

    function run() public {
        uint8 answer = uint8(uint256(keccak256(abi.encodePacked(blockhash(targetBlockNumber - 1), targetTimestamp))));

        vm.broadcast();
        GuessTheRandomNumberChallenge challenge =
            GuessTheRandomNumberChallenge(0x27EF01Aeff046C19D08f366161f57CD253e21a47);
        challenge.guess{value: 1 ether}(answer);
    }
}

interface GuessTheRandomNumberChallenge {
    function guess(uint8 n) external payable;
}
