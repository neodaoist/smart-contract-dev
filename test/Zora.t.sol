// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ERC721Contract} from "../src/sm/ERC721Contract.sol";

contract ZoraTest is Test {
    //
    ReserveAuctionCoreEth zReserve;
    Asks zAsks;

    ERC721Contract nft;

    address owner = address(0xCAFE);

    // Goerli addresses
    address MODULE_MANAGER = 0x9458E29713B98BF452ee9B2C099289f533A5F377;
    address ERC20_TRANSFER_HELPER = 0x53172d999a299198a935f9E424f9f8544e3d4292;
    address ERC721_TRANSFER_HELPER = 0xd1adAF05575295710dE1145c3c9427c364A70a7f;
    address RESERVE_AUCTION_CORE_ETH = 0x2506D9F5A2b0E1A2619bCCe01CD3e7C289A13163;
    address RESERVE_AUCTION_CORE_ERC20 = 0x1Ee71c10e7Dd6c7FbDC891dE4E902e041e1F5d33;
    address RESERVE_AUCTION_FINDERS_ETH = 0x29a6237e646A5A189dB197A48cB96fa7944A32a2;
    address RESEVER_AUCTION_FINDERS_ERC20 = 0x36aB5200426715a9dD414513912970cb7d659b3C;
    address ASKS = 0xd8be3E8A8648c4547F06E607174BAC36f5684756;
    address OFFERS = 0x3a98377E8e67D01a3D21E30eCE6A4703eeB4d25a;

    function setUp() public {
        // Fork
        vm.createSelectFork(vm.envString("GOERLI_RPC_URL"), 7687369);

        // Deploy NFT contract and mint one
        nft = new ERC721Contract("Handrolled NFT", "ROLLUP");
        nft.mint(owner, 1337);

        // Get Zora modules
        zReserve = ReserveAuctionCoreEth(RESERVE_AUCTION_CORE_ETH);
        zAsks = Asks(ASKS);

        // Approve Zora transfer helper(s) and module(s)
        vm.startPrank(owner);
        nft.setApprovalForAll(ERC721_TRANSFER_HELPER, true);
        ModuleManager(MODULE_MANAGER).setApprovalForModule(RESERVE_AUCTION_CORE_ETH, true);
        ModuleManager(MODULE_MANAGER).setApprovalForModule(ASKS, true);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        Reserve Auction
    //////////////////////////////////////////////////////////////*/

    function test_createAuction_whenOwner() public {
        vm.prank(owner);
        zReserve.createAuction(address(nft), 1337, 3 days, 0.1 ether, address(0xABCD), block.timestamp);

        (address seller, uint256 reservePrice, address fundsRecipient,,, uint256 duration, uint256 startTime,) =
            zReserve.auctionForNFT(address(nft), 1337);

        assertEq(seller, owner);
        assertEq(reservePrice, 0.1 ether);
        assertEq(fundsRecipient, address(0xABCD));
        assertEq(duration, 3 days);
        assertEq(startTime, block.timestamp);
    }

    function test_createAuction_whenOperator() public {
        vm.prank(owner);
        nft.setApprovalForAll(address(0xABCD), true);

        vm.prank(address(0xABCD));
        zReserve.createAuction(address(nft), 1337, 3 days, 0.1 ether, address(0xABCD), block.timestamp);

        (address creator,,,,,,,) = zReserve.auctionForNFT(address(nft), 1337);

        assertEq(creator, owner);
    }

    function test_createAuction_whenNotOwnerOrOperator_shouldRevert() public {
        vm.expectRevert("ONLY_TOKEN_OWNER_OR_OPERATOR");

        zReserve.createAuction(address(nft), 1337, 3 days, 0.1 ether, address(0xABCD), block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        Asks
    //////////////////////////////////////////////////////////////*/

    function testScenario_createAsk_updateAskPrice_fillAsk() public {
        vm.prank(owner);
        zAsks.createAsk(
            address(nft),
            1337,
            0.1 ether,
            address(0), // create ask in ETH currency
            owner,
            0
        );

        (address seller, address sellerFundsRecipient, address askCurrency, uint16 findersFeeBps, uint256 askPrice) =
            zAsks.askForNFT(address(nft), 1337);
        assertEq(seller, owner);

        // TODO continue
    }
}

/*//////////////////////////////////////////////////////////////
                    Zora v3 – Models
//////////////////////////////////////////////////////////////*/

struct Auction {
    //
    address seller;
    uint96 reservePrice;
    address sellerFundsRecipient;
    uint96 highestBid;
    address highestBidder;
    uint32 duration;
    uint32 startTime;
    uint32 firstBidTime;
}

struct Ask {
    //
    address seller;
    address sellerFundsRecipient;
    address askCurrency;
    uint16 findersFeeBps;
    uint256 askPrice;
}

/*//////////////////////////////////////////////////////////////
                    Zora v3 – Interfaces
//////////////////////////////////////////////////////////////*/

interface ModuleManager {
    function setApprovalForModule(address _moduleAddress, bool _approved) external;
}

interface ReserveAuctionCoreEth {
    //
    function createAuction(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _reservePrice,
        address _sellerFundsRecipient,
        uint256 _startTime
    ) external;

    function setAuctionReservePrice(address _tokenContract, uint256 _tokenId, uint256 _reservePrice) external;

    function cancelAuction(address _tokenContract, uint256 _tokenId) external;

    function createBid(address _tokenContract, uint256 _tokenId) external;

    function settleAuction(address _tokenContract, uint256 _tokenId) external;

    /// @dev ERC-721 contract address => (ERC-721 token ID => Auction)
    function auctionForNFT(address _tokenContract, uint256 _tokenId)
        external
        returns (address, uint96, address, uint96, address, uint32, uint32, uint32);
}

interface Asks {
    //
    function createAsk(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _askPrice,
        address _askCurrency,
        address _sellerFundsRecipient,
        uint16 _findersFeeBps
    ) external;

    /// @dev ERC-721 contract address => (ERC-721 token ID => Ask)
    function askForNFT(address _tokenContract, uint256 _tokenId)
        external
        returns (address, address, address, uint16, uint256);
}
