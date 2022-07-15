// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";

contract ForkingCheatcodesTest is Test {
    //
    uint256 mainnetFork;
    uint256 optimismFork;

    string constant MAINNET_RPC_URL = "";
    string constant OPTIMISM_RPC_URL = "";
    string constant ARBITRUM_RPC_URL = "";

    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        optimismFork = vm.createFork(OPTIMISM_RPC_URL);
    }

    function testForkIdDiffer() public {
        assert(mainnetFork != optimismFork);
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
}
