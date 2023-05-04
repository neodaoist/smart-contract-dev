// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract NicknameScript is Script {
    //
    address cteAddress = 0x71c46Ed333C35e4E6c62D32dc7C8F00D125b4fee;

    function run() public {
        vm.broadcast();
        CaptureTheEther cte = CaptureTheEther(cteAddress);
        cte.setNickname("neodaoist");
    }
}

interface CaptureTheEther {
    function setNickname(bytes32 nickname) external;
}
