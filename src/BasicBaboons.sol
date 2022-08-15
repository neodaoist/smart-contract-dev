// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {ERC721} from "openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Royalty} from "openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {Counters} from "openzeppelin/contracts/utils/Counters.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";

contract BasicBaboons is ERC721Royalty, Ownable {
    //
    using Counters for Counters.Counter;

    event Withdrawal(uint256 amount);
    event MaxSupplyUpdated(uint256 newSupply);
    event URIUpdated(string uri);
    event URIFrozen();
    event RoyaltyUpdated(address indexed receiver, uint96 royaltyPercentageInBips);

    Counters.Counter internal nextId;

    uint256 public maxSupply = 1000;
    uint256 internal constant MINT_PRICE = 0.05 ether;

    bytes32 public immutable provenanceHash;

    uint8 internal immutable teamAllocation;
    address internal immutable teamMultisig;

    mapping(address => bool) public allowlisted;

    uint96 INITIAL_ROYALTY_PERCENTAGE_IN_BIPS = 500;
    uint96 MAX_ROYALTY_PERCENTAGE_IN_BIPS = 1000;
    
    string internal baseURI = "https://originaluri.xyz/";

    bool internal uriFrozen;
    
    /// @param _teamMultisig Multisig address of the project team
    /// @param _teamAllocation Number of tokens to be minted to the project team
    /// @param _allowlist Addresses to allowlist
    /// @param _provenanceHash 32-byte hash of the metadata
    constructor (address _teamMultisig, uint8 _teamAllocation, address[] memory _allowlist, bytes32 _provenanceHash) ERC721("Basic Baboons", "BBB") public {
        nextId.increment(); // start at 1        

        teamMultisig = _teamMultisig;
        teamAllocation = _teamAllocation;
        provenanceHash = _provenanceHash;

        transferOwnership(teamMultisig);
        setupAllowlist(_allowlist);
        mintTeamAllocation();
        _setDefaultRoyalty(teamMultisig, INITIAL_ROYALTY_PERCENTAGE_IN_BIPS);
    }

    function setupAllowlist(address[] memory _allowlist) internal {
        for (uint256 i = 0; i < _allowlist.length; i++) {
            allowlisted[_allowlist[i]] = true;
        }
    }

    function mintTeamAllocation() internal {
        for (uint256 i = 0; i < teamAllocation; i++) {
            _mint(teamMultisig);
        }
    }

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

        emit Withdrawal(amount);
    }

    /// @notice Reduce the max supply
    /// @param _newSupply New max supply
    function reduceSupply(uint256 _newSupply) external onlyOwner {
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

    /// @notice
    /// @param
    function setURI(string memory _uri) public onlyOwner {
        require(!uriFrozen, "URI is frozen and cannot be updated");

        baseURI = _uri;

        emit URIUpdated(_uri);
    }

    /// @notice 
    function freezeURI() public onlyOwner {
        require(!uriFrozen, "URI already frozen");

        uriFrozen = true;

        emit URIFrozen();
    }

    /// @notice Set a new royalty
    /// @param _newRoyaltyPercentageInBips The new royalty percentage in basis points,
    /// must not exceed 10% (1000 bips)
    function setNewRoyalty(uint96 _newRoyaltyPercentageInBips) external onlyOwner {
        require(_newRoyaltyPercentageInBips <= MAX_ROYALTY_PERCENTAGE_IN_BIPS, "New royalty percentage must not exceed 10%");

        _setDefaultRoyalty(owner(), _newRoyaltyPercentageInBips);

        emit RoyaltyUpdated(owner(), _newRoyaltyPercentageInBips);
    }
}
