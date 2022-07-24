// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";
import {Surl} from "surl/Surl.sol";

contract SurlTest is Test {
    //
    using Surl for *;

    function run() public {
        (uint256 status, bytes memory data) = "https://book.getfoundry.sh/".get();
        emit logs(data);
    }
}
