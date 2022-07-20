// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";

contract ForkDocsTest is Test {
    //
    // Cheats constant cheats = Cheats(HEVM_ADDRESS);

    // the identifiers of the forks
    uint256 mainnetFork;
    uint256 optimismFork;

    // this will create two _different_ forks during setup
    function setUp() public {
        mainnetFork = vm.createFork("https://mainnet.infura.io/v3/3b59d7ee7a5f4378911a8a8789911ed1");
        optimismFork = vm.createFork("https://optimism-mainnet.infura.io/v3/3b59d7ee7a5f4378911a8a8789911ed1");
    }

    // Fork ids are unique
    function testForkIdDiffer() public {
        assert(mainnetFork != optimismFork);
    }

    // ensures forks use different ids
    function testCanSelectFork() public {
        // select the fork
        vm.selectFork(mainnetFork);
        assertEq(mainnetFork, vm.activeFork());
        // from here on data is fetched from the `mainnetFork` if the EVM requests it
    }

    function testCanSwitchContracts() public {
        vm.selectFork(mainnetFork);
        assertEq(mainnetFork, vm.activeFork());

        vm.selectFork(optimismFork);
        assertEq(optimismFork, vm.activeFork());
    }

    // Forks can be created at all times
    function testCanCreateAndSelectInOneStep() public {
        // creates a new fork and also selects it
        uint256 anotherFork = vm.createSelectFork("https://mainnet.infura.io/v3/3b59d7ee7a5f4378911a8a8789911ed1");
    }
}
