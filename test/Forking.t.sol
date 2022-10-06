// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/sm/ERC20Contract.sol";

contract ForkingTest is Test {
    // //
    // ERC20Contract erc20;
    // address contractAddr = 0x1EE488D6B0f02b080Fa6740831a3B584B1D4fA53;
    // address deployerAddr = 0x79847aA966193633a706A644AEaB42ae9675da27;
    // // % forge test --match-contract ForkingTest --fork-url <rpcURL> --fork-block-number <blockNumber>
    // // chain-id is goerli
    // // deployed at block 7123826
    // // minted 100 at block 7123831
    // function setUp() public {
    //     erc20 = ERC20Contract(contractAddr);
    // }
    // function testInvariantMetadata() public {
    //     assertEq(erc20.name(), "Neotoke Nine");
    //     assertEq(erc20.symbol(), "NEONINE");
    //     assertEq(erc20.decimals(), 9);
    // }
    // function testCurrentEtherBalance() public {
    //     assertEq(contractAddr.balance, 0);
    // }
    // function testCurrentTotalSupply() public {
    //     assertEq(erc20.totalSupply(), 100e9);
    // }
    // function testCurrentDeployerBalanceOf() public {
    //     assertEq(erc20.balanceOf(deployerAddr), 100e9);
    // }
    // function testMint() public {
    //     erc20.mint(address(0xBABE), 10e9);
    //     assertEq(erc20.balanceOf(address(0xBABE)), 10e9);
    //     assertEq(erc20.totalSupply(), 110e9);
    // }
    // function testBurn() public {
    //     erc20.mint(address(0xBABE), 10e9);
    //     erc20.burn(address(0xBABE), 1e9);
    //     assertEq(erc20.balanceOf(address(0xBABE)), 9e9);
    //     assertEq(erc20.totalSupply(), 109e9);
    // }
}
