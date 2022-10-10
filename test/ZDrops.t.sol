// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.10;

// import {Vm} from "forge-std/Vm.sol";
// import {DSTest} from "ds-test/test.sol";
// import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";

// import {IERC721Drop} from "../src/interfaces/IERC721Drop.sol";
// import {ERC721Drop} from "../src/ERC721Drop.sol";
// import {ZoraFeeManager} from "../src/ZoraFeeManager.sol";
// import {DummyMetadataRenderer} from "./utils/DummyMetadataRenderer.sol";
// import {MockUser} from "./utils/MockUser.sol";
// import {IMetadataRenderer} from "../src/interfaces/IMetadataRenderer.sol";
// import {FactoryUpgradeGate} from "../src/FactoryUpgradeGate.sol";
// import {ERC721DropProxy} from "../src/ERC721DropProxy.sol";

// contract ZDropsTest is DSTest {
//     //
//     event FundsWithdrawn(
//         address indexed withdrawnBy,
//         address indexed withdrawnTo,
//         uint256 amount,
//         address feeRecipient,
//         uint256 feeAmount
//     );

//     ERC721Drop drop;

//     MockUser mockUser;
//     Vm public constant vm = Vm(HEVM_ADDRESS);
//     DummyMetadataRenderer public dummyRenderer = new DummyMetadataRenderer();
//     ZoraFeeManager public feeManager;
//     FactoryUpgradeGate public factoryUpgradeGate;
//     address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);
//     address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS =
//         payable(address(0x21303));
//     address payable public constant DEFAULT_ZORA_DAO_ADDRESS =
//         payable(address(0x999));
//     address public constant UPGRADE_GATE_ADMIN_ADDRESS = address(0x942924224);
//     address public constant mediaContract = address(0x123456);
//     address public impl;

//     struct Configuration {
//         IMetadataRenderer metadataRenderer;
//         uint64 editionSize;
//         uint16 royaltyBPS;
//         address payable fundsRecipient;
//     }

//     function setUp() public {
//         vm.prank(DEFAULT_ZORA_DAO_ADDRESS);
//         feeManager = new ZoraFeeManager(500, DEFAULT_ZORA_DAO_ADDRESS);
//         factoryUpgradeGate = new FactoryUpgradeGate(UPGRADE_GATE_ADMIN_ADDRESS);
//         vm.prank(DEFAULT_ZORA_DAO_ADDRESS);
//         impl = address(
//             new ERC721Drop(feeManager, address(0x1234), factoryUpgradeGate)
//         );
//         address payable newDrop = payable(
//             address(new ERC721DropProxy(impl, ""))
//         );
//         drop = ERC721Drop(newDrop);
//     }

//     function test_Init() public {
//         drop.initialize({
//             _contractName: "Test Mutant Ninja Turtles",
//             _contractSymbol: "TMNT",
//             _initialOwner: DEFAULT_OWNER_ADDRESS,
//             _fundsRecipient: payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS),
//             _editionSize: 138,
//             _royaltyBPS: 1000,
//             _metadataRenderer: dummyRenderer,
//             _metadataRendererInit: "",
//             _salesConfig: IERC721Drop.SalesConfiguration({
//                 publicSaleStart: 0,
//                 publicSaleEnd: 0,
//                 presaleStart: 0,
//                 presaleEnd: 0,
//                 publicSalePrice: 0,
//                 maxSalePurchasePerAddress: 0,
//                 presaleMerkleRoot: bytes32(0)
//             })
//         });

//         assertEq(drop.owner(), DEFAULT_OWNER_ADDRESS);

//         (
//             IMetadataRenderer renderer,
//             uint64 editionSize,
//             uint16 royaltyBPS,
//             address payable fundsRecipient
//         ) = drop.config();

//         assertEq(address(renderer), address(dummyRenderer));
//         assertEq(editionSize, 138);
//         assertEq(royaltyBPS, 1000);
//         assertEq(fundsRecipient, payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS));

//         assertEq(drop.name(), "Test Mutant Ninja Turtles");
//         assertEq(drop.symbol(), "TMNT");        
//     }
// }
