// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";

import {AccessControl} from "openzeppelin/contracts/access/AccessControl.sol";

import {Strings} from "openzeppelin/contracts/utils/Strings.sol";

// event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
// event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
// event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)

// modifier onlyRole(bytes32 role)

// function hasRole(bytes32 role, address account) view
// function getRoleAdmin(bytes32 role) view

// function grantRole(bytes32 role, address account)
// function revokeRole(bytes32 role, address account)
// function renounceRole(bytes32 role, address account)

// Test Ideas:
// - contract is constructed with correct roles and grantees
// - events firing every which way
// - access when have role, when have different role, when used to have role, when don't have any role
// - granting role
// - revoking role
// - renouncing role
// - more about role admin fancier biz logic

contract AccessControlContract is AccessControl {
    //
    // implicit – DEFAULT_ADMIN_ROLE = 0x00                                  // 1 admin
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE"); // 2 developers
    bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE"); // 3 writers
    bytes32 public constant READER_ROLE = keccak256("READER_ROLE"); // 4 readers

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function handleAdminBusiness() public onlyRole(DEFAULT_ADMIN_ROLE) {
        //
    }

    function handleDevBusiness() public onlyRole(DEVELOPER_ROLE) {
        //
    }

    // TODO explore how to control access to 1+ role
    function handleWriterBusiness() public onlyRole(WRITER_ROLE) {
        //
    }

    function handlePublicBusiness() public {
        //
    }
}

contract AccessControlTest is Test {
    //
    AccessControlContract ac;

    // implicit — ADMIN1 = address(this)
    address public constant DEV1 = address(0x01a);
    address public constant DEV2 = address(0x01b);
    address public constant WRITER1 = address(0x02a);
    address public constant WRITER2 = address(0x02b);
    address public constant WRITER3 = address(0x02c);
    address public constant READER1 = address(0x03a);
    address public constant READER2 = address(0x03b);
    address public constant READER3 = address(0x03c);
    address public constant READER4 = address(0x03d);

    function setUp() public {
        ac = new AccessControlContract();
    }

    function testHandleAdminBusiness() public {
        // no revert
        ac.handleAdminBusiness();
    }

    function testHandleAdminBusinessCantBeCalledByNonAdmin() public {
        // "AccessControl: account 0x00000000000000000000000000000000000abcd1 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        expectRevertNotAdmin(0xABCD1);

        vm.prank(address(0xABCD1));
        ac.handleAdminBusiness();
    }

    // function testGrantRole() public {
    //     ac.grantRole(keccak256("DEVELOPER_ROLE"), DEV1);
    //     ac.grantRole(keccak256("DEVELOPER_ROLE"), DEV2);

    //     expectRevertNotRole(0xABCD, "DEVELOPER_ROLE");

    //     vm.prank(address(0xABCD));
    //     ac.handleDevBusiness();
    // }

    function expectRevertNotAdmin(uint256 _rawAddress) public {
        vm.expectRevert(
            bytes(
                string.concat(
                    "AccessControl: account ",
                    Strings.toHexString(_rawAddress, 20),
                    " is missing role ",
                    Strings.toHexString(0x00, 32)
                )
            )
        );
    }

    // function expectRevertNotRole(uint256 _rawAddress, string memory _role) public {
    //     vm.expectRevert(
    //         bytes(
    //             string.concat(
    //                 "AccessControl: account ",
    //                 Strings.toHexString(_rawAddress, 20),
    //                 " is missing role ",
    //                 string(bytes(keccak256(abi.encode(_role))))
    //             )
    //         )
    //     );
    // }
}
