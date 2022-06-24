// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {ERC721} from "openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Contract is ERC721 {
    //
    constructor() ERC721("Epique NFT", "EPIQUE") {}
}
