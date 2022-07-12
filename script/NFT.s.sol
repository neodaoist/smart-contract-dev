// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/NFT.sol";

contract NFTScript is Script {
    //
    function run() external {
        vm.startBroadcast();

        NFT nft = new NFT("NFT Tutorial", "TUT", "baseUri");

        vm.stopBroadcast();
    }
}
