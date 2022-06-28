// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {ERC721} from "openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Contract is ERC721 {
    //
    constructor() ERC721("Epique NFT", "EPIQUE") {}

    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        return "ipfs://bafkreifueofjqgxahz2wthmjgj64pkiota4v5oxvvvgfzthx234lljag7i";
    }

    /*//////////////////////////////////////////////////////////////
                        from OZ ERC721Mock.sol
    //////////////////////////////////////////////////////////////*/

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        _safeMint(to, tokenId, _data);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}
