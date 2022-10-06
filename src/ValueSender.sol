// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";

contract ValueSender is ERC721 {
    //
    uint256 private tokenID;
    mapping(uint256 => string) private messages;

    constructor() ERC721("Value Sender", "VALUE") {}

    function tokenURI(uint256 _tokenID) public view override returns (string memory) {
        return messages[_tokenID];
    }

    function mint(address _to, string memory _message) public payable returns (uint256) {
        _mint(_to, tokenID++);
        messages[tokenID] = _message;

        payable(_to).transfer(msg.value);

        return tokenID;
    }
}
