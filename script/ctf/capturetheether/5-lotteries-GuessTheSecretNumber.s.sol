// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract GuessTheSecretNumberChallengeScript is Script {
    //
    bytes32 targetHash = 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;

    function run() public {
        uint8 answer;
        bool solved;

        for (answer = 0; answer < 256; answer++) {
            if (keccak256(abi.encodePacked(answer)) == targetHash) {
                solved = true;
                break;
            }
        }

        if (solved) {
            vm.broadcast();
            GuessTheSecretNumberChallenge challenge =
                GuessTheSecretNumberChallenge(0x6C660eF77cc47B43a8De787926aF682484F89063);
            challenge.guess{value: 1 ether}(answer);
        }
    }
}

interface GuessTheSecretNumberChallenge {
    function guess(uint8 n) external payable;
}
