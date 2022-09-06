// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {ERC721} from "openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Royalty} from "openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {Counters} from "openzeppelin/contracts/utils/Counters.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";

/// @dev Container library for events, in order to share between production and test code
library BasicBaboonEvents {
    event Withdrawal(uint256 amount);
    event MaxSupplyUpdated(uint256 newSupply);
    event URIUpdated(string uri);
    event URIFrozen();
    event RoyaltyUpdated(address indexed receiver, uint96 royaltyPercentageInBips);
}

/// @notice Basic Baboons is a ground-breaking, totally original, totally awesome NFT collection =)
contract BasicBaboons is ERC721Royalty, Ownable {
    //
    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                        Public State Variables
    //////////////////////////////////////////////////////////////*/

    uint256 public maxSupply = 1000;
    mapping(address => bool) public allowlisted;

    bytes32 public immutable provenanceHash;

    /*//////////////////////////////////////////////////////////////
                        Internal State Variables
    //////////////////////////////////////////////////////////////*/

    Counters.Counter internal nextId;
    string internal baseURI = "https://originaluri.xyz/";
    bool internal uriFrozen;

    uint8 internal immutable teamAllocation;
    address internal immutable teamMultisig;

    uint256 internal constant MINT_PRICE = 0.05 ether;
    uint96 internal constant INITIAL_ROYALTY_PERCENTAGE_IN_BIPS = 500;
    uint96 internal constant MAX_ROYALTY_PERCENTAGE_IN_BIPS = 1000;

    /*//////////////////////////////////////////////////////////////
                        Constructor
    //////////////////////////////////////////////////////////////*/

    /// @param _teamMultisig Multisig address of the project team
    /// @param _teamAllocation Number of tokens to be minted to the project team
    /// @param _allowlist Addresses to allowlist
    /// @param _provenanceHash 32-byte hash of the metadata
    constructor(address _teamMultisig, uint8 _teamAllocation, address[] memory _allowlist, bytes32 _provenanceHash)
        ERC721("Basic Baboons", "BBB")
    {
        nextId.increment(); // start at tokenId 1

        teamMultisig = _teamMultisig;
        teamAllocation = _teamAllocation;
        provenanceHash = _provenanceHash;

        _transferOwnership(teamMultisig);
        _setupAllowlist(_allowlist);
        _mintTeamAllocation();
        _setDefaultRoyalty(teamMultisig, INITIAL_ROYALTY_PERCENTAGE_IN_BIPS);
    }

    function _setupAllowlist(address[] memory _allowlist) internal {
        for (uint256 i = 0; i < _allowlist.length; i++) {
            allowlisted[_allowlist[i]] = true;
        }
    }

    function _mintTeamAllocation() internal {
        for (uint256 i = 0; i < teamAllocation; i++) {
            _mint(teamMultisig);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        External/Public Views
    //////////////////////////////////////////////////////////////*/

    /// @notice Retrieve the total number of tokens minted
    /// @return Total tokens minted
    function totalSupply() public view returns (uint256) {
        return nextId.current() - 1;
    }

    /*//////////////////////////////////////////////////////////////
                        External/Public Transactions
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint an NFT to the sender
    function mint() external payable {
        require(msg.value == MINT_PRICE, "Mint price of 0.05 ETH not paid");
        require(nextId.current() <= maxSupply, "Max supply already reached");

        _mint(msg.sender);
    }

    /// @notice Mint an NFT to an allowlisted address
    function mintAllowlist() external {
        require(allowlisted[msg.sender], "Address not allowlisted");

        allowlisted[msg.sender] = false;

        _mint(msg.sender);
    }

    function _mint(address _address) internal {
        uint256 tokenId = nextId.current();
        nextId.increment();
        _mint(_address, tokenId);
    }

    /// @notice Withdraw the contract's ether balance
    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);

        emit BasicBaboonEvents.Withdrawal(amount);
    }

    /// @notice Reduce the max supply
    /// @param _newSupply New max supply
    function reduceSupply(uint256 _newSupply) external onlyOwner {
        require(
            _newSupply < maxSupply && _newSupply >= totalSupply(),
            "New supply must be < previous max supply and >= total supply"
        );

        maxSupply = _newSupply;

        emit BasicBaboonEvents.MaxSupplyUpdated(_newSupply);
    }

    /// @notice Set a new URI
    /// @param _newURI New URI string
    function setURI(string memory _newURI) public onlyOwner {
        require(!uriFrozen, "URI is frozen and cannot be updated");

        baseURI = _newURI;

        emit BasicBaboonEvents.URIUpdated(_newURI);
    }

    /// @notice Freeze the URI, preventing any more updates
    function freezeURI() public onlyOwner {
        require(!uriFrozen, "URI already frozen");

        uriFrozen = true;

        emit BasicBaboonEvents.URIFrozen();
    }

    /// @notice Set a new royalty
    /// @param _newRoyaltyPercentageInBips The new royalty percentage in basis points,
    /// must not exceed 10% (1000 bips)
    function setNewRoyalty(uint96 _newRoyaltyPercentageInBips) external onlyOwner {
        require(
            _newRoyaltyPercentageInBips <= MAX_ROYALTY_PERCENTAGE_IN_BIPS, "New royalty percentage must not exceed 10%"
        );

        _setDefaultRoyalty(owner(), _newRoyaltyPercentageInBips);

        emit BasicBaboonEvents.RoyaltyUpdated(owner(), _newRoyaltyPercentageInBips);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal/Private Views
    //////////////////////////////////////////////////////////////*/

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
