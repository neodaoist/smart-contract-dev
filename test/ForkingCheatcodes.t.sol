// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";

contract ForkingCheatcodesTest is Test {
    //
    uint256 mainnetFork;
    uint256 optimismFork;

    uint256 contractData;

    IWETH WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address constant WETH_TOKEN_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 constant mainblock = 15_151_704;

    string constant MAINNET_RPC_URL = "https://mainnet.infura.io/v3/3b59d7ee7a5f4378911a8a8789911ed1";
    string constant OPTIMISM_RPC_URL = "https://optimism-mainnet.infura.io/v3/3b59d7ee7a5f4378911a8a8789911ed1";
    string constant ARBITRUM_RPC_URL = "https://arbitrum-mainnet.infura.io/v3/3b59d7ee7a5f4378911a8a8789911ed1";

    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        optimismFork = vm.createFork(OPTIMISM_RPC_URL);

        contractData = 123;
    }

    function testBlankTest() public {
        uint256 optimismForkId = vm.createFork(OPTIMISM_RPC_URL);

        vm.rollFork(optimismForkId, 1_337_000);

        vm.selectFork(optimismForkId);

        assertEq(block.number, 1_337_000);
    }

    function testForkIdDiffer() public {
        assert(mainnetFork != optimismFork);
    }

    function testFail_activeFork_whenNoActiveFork_shouldRevert() public {
        vm.activeFork(); // TODO should this have a revert message to help debug a malformed test?
    }

    function testCreateForkWithBlock() public {
        assertEq(block.number, 1);

        uint256 id = vm.createFork(MAINNET_RPC_URL, 456);
        vm.selectFork(id);

        assertEq(block.number, 456);
    }

    function testCanSelectFork() public {
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
    }

    function testCanSwitchForks() public {
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);

        vm.selectFork(optimismFork);
        assertEq(vm.activeFork(), optimismFork);
    }

    function testCanCreateAndSelectInOneStep() public {
        uint256 arbitrumFork = vm.createSelectFork(ARBITRUM_RPC_URL);
        assertEq(vm.activeFork(), arbitrumFork);
    }

    function testRollFork() public {
        vm.selectFork(optimismFork);

        vm.rollFork(1337);

        assertEq(vm.activeFork(), optimismFork);
        assertEq(block.number, 1337);
    }

    function testRollInactiveFork() public {
        vm.selectFork(mainnetFork);
        vm.rollFork(123);

        assertEq(vm.activeFork(), mainnetFork);
        assertEq(block.number, 123);

        vm.rollFork(optimismFork, 456);

        assertEq(vm.activeFork(), mainnetFork);
        assertEq(block.number, 123);

        vm.selectFork(optimismFork);

        assertEq(vm.activeFork(), optimismFork);
        assertEq(block.number, 456);
    }

    function testPracticeDirectOnStorageSlot() public {
        // 0x4BBa239C9cC83619228457502227D801e4738bA0
        // 777940133568685575
        // 0xbcfb221e9342dcd5de3d9275da6423d236f891cdb48b8b7b2034f7283cdc6058

        // $ cast index address 0x4BBa239C9cC83619228457502227D801e4738bA0 3

        // TODO research if cast-index accepts value_type (seems no), and consider PR to update Foundry book
        // (https://book.getfoundry.sh/reference/cast/cast-index)

        vm.selectFork(mainnetFork);

        address me = 0x4BBa239C9cC83619228457502227D801e4738bA0;

        assertEq(WETH.balanceOf(me), 777_940_133_568_685_575);

        vm.store(
            WETH_TOKEN_ADDR,
            0xbcfb221e9342dcd5de3d9275da6423d236f891cdb48b8b7b2034f7283cdc6058,
            bytes32(uint256(1337))
        );

        assertEq(WETH.balanceOf(me), 1337);
    }

    // practice with storage slot for allowance

    // testCanHaveForkSpecificData

    // testCanHaveContractData

    function test_warpFork() public {
        assertEq(block.timestamp, 1);
        vm.warp(2_000_000_000);
        assertEq(block.timestamp, 2_000_000_000);

        vm.selectFork(mainnetFork);

        emit log_uint(block.timestamp);
        vm.warp(2_000_000_000);
        assertEq(block.timestamp, 2_000_000_000);
    }

    function test_rollFork() public {
        assertEq(block.number, 1);
        vm.roll(123);
        assertEq(block.number, 123);

        vm.selectFork(mainnetFork);

        emit log_uint(block.number);
        vm.roll(456); // doesn't have to rollFork
        assertEq(block.number, 456);
    }
}

interface IWETH {
    function deposit() external payable;

    function balanceOf(address) external view returns (uint256);
}
