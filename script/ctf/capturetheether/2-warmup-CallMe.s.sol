// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract CallMeScript is Script {
    //
    function run() public {
        vm.broadcast();
        CallMeChallenge challenge = CallMeChallenge(0xC2CFD040D658d1558Be580b66A8c997F7b459f51);
        challenge.callme();
    }
}

interface CallMeChallenge {
    function callme() external;
}
