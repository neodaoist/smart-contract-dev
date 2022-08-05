// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {ERC721} from "openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Counters} from "openzeppelin/contracts/utils/Counters.sol";

contract BasicBaboons is ERC721 {
    //
    using Counters for Counters.Counter;

    event Withdrawal(uint256 amount);
    event MaxSupplyUpdated(uint256 newSupply);
    event URIUpdated(string uri);
    event URIFrozen();

    Counters.Counter internal nextId;

    uint256 public maxSupply = 1000;

    uint8 internal immutable teamAllocation;
    address internal immutable teamMultisig;
    
    string internal baseURI = "https://originaluri.xyz/";

    bool internal uriFrozen;
    
    /// @param _teamMultisig Multisig address of the project team
    /// @param _teamAllocation Number of tokens to be minted to the project team
    constructor (address _teamMultisig, uint8 _teamAllocation) ERC721("Basic Baboons", "BBB") public {
        nextId.increment(); // start at 1

        teamMultisig = _teamMultisig;
        teamAllocation = _teamAllocation;
        mintTeamAllocation();
    }

    function mintTeamAllocation() internal {
        for (uint256 i = 0; i < teamAllocation; i++) {
            _mint(teamMultisig, nextId.current());
            nextId.increment();
        }
    }

    /// @notice Mint an NFT to the sender
    function mint() external payable {
        require(msg.value == 0.05 ether, "Mint price of 0.05 ETH not paid");
        uint256 tokenId = nextId.current();
        require(tokenId <= maxSupply, "Max supply already reached");

        nextId.increment();

        _mint(msg.sender, tokenId);
    }

    /// @notice Withdraw the contract's ether balance
    function withdraw() external {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);

        emit Withdrawal(amount);
    }

    /// @notice Reduce the max supply
    /// @param _newSupply New max supply
    function reduceSupply(uint256 _newSupply) external {
        require(_newSupply < maxSupply && _newSupply >= totalSupply(),
            "New supply must be < previous max supply and >= total supply");

        maxSupply = _newSupply;

        emit MaxSupplyUpdated(_newSupply);
    }

    /// @notice Retrieve the total number of tokens minted
    /// @return Total tokens minted
    function totalSupply() public view returns (uint256) {
        return nextId.current() - 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setURI(string memory _uri) public {
        require(!uriFrozen, "URI is frozen and cannot be updated");

        baseURI = _uri;

        emit URIUpdated(_uri);
    }

    function freezeURI() public {
        require(!uriFrozen, "URI already frozen");

        uriFrozen = true;

        emit URIFrozen();
    }
}
