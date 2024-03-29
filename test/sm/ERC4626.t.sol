// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {ERC20Contract} from "../../src/sm/ERC20Contract.sol";
import {ERC4626Contract} from "../../src/sm/ERC4626Contract.sol";

contract ERC4626Test is Test {
    //
    ERC20Contract underlying;
    ERC4626Contract vault;

    function setUp() public {
        underlying = new ERC20Contract("Token", "TKN", 18);
        vault = new ERC4626Contract(underlying, "Mock Token Vault", "vwTKN");
    }

    // Events
    // Deposit
    // Withdraw

    // Views
    // function asset() public view returns (address)
    // function totalAssets() public view returns (uint256)
    // totalSupply
    // balanceOf
    // function convertToShares(uint256 assets) public view returns (uint256 shares)
    // function convertToAssets(uint256 shares) public view returns (uint256 assets)
    // maxDeposit
    // previewDeposit
    // maxMint
    // previewMint
    // maxWithdraw
    // previewWithdraw
    // maxRedeem
    // previewRedeem

    // Transactions
    // deposit
    // mint
    // withdraw
    // redeem

    // 16 Tests

    /*//////////////////////////////////////////////////////////////
                        Unit Tests
    //////////////////////////////////////////////////////////////*/

    function testInvariantMetadata() public {
        assertEq(vault.name(), "Mock Token Vault");
        assertEq(vault.symbol(), "vwTKN");
        assertEq(vault.decimals(), 18);
    }

    // function testDepositShouldXYZ() public {

    // }

    // function testDepositShouldEmitEvent() public {

    // }

    // function testDepositWhenRoundingErrorShouldFail() public {

    // }

    /*//////////////////////////////////////////////////////////////
                        Component Tests
    //////////////////////////////////////////////////////////////*/

    function testSingleDepositWithdraw(uint128 amount) public {
        if (amount == 0) amount = 1;

        uint256 aliceUnderlyingAmount = amount;

        address alice = address(0xABCD);

        underlying.mint(alice, aliceUnderlyingAmount);

        vm.prank(alice);
        underlying.approve(address(vault), aliceUnderlyingAmount);
        assertEq(underlying.allowance(alice, address(vault)), aliceUnderlyingAmount);

        uint256 alicePreDepositBal = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 aliceShareAmount = vault.deposit(aliceUnderlyingAmount, alice);

        assertEq(vault.afterDepositHookCalledCounter(), 1);

        // Expect exchange rate to be 1:1 on initial deposit
        assertEq(aliceUnderlyingAmount, aliceShareAmount);
        assertEq(vault.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
        assertEq(vault.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
        assertEq(vault.totalSupply(), aliceShareAmount);
        assertEq(vault.totalAssets(), aliceUnderlyingAmount);
        assertEq(vault.balanceOf(alice), aliceShareAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);

        vm.prank(alice);
        vault.withdraw(aliceUnderlyingAmount, alice, alice);

        assertEq(vault.beforeWithdrawHookCalledCounter(), 1);

        assertEq(vault.totalAssets(), 0);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal);
    }

    function testSingleMintRedeem(uint128 amount) public {
        if (amount == 0) amount = 1;

        uint256 aliceShareAmount = amount;

        address alice = address(0xABCD);

        underlying.mint(alice, aliceShareAmount);

        vm.prank(alice);
        underlying.approve(address(vault), aliceShareAmount);
        assertEq(underlying.allowance(alice, address(vault)), aliceShareAmount);

        uint256 alicePreDepositBal = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 aliceUnderlyingAmount = vault.mint(aliceShareAmount, alice);

        assertEq(vault.afterDepositHookCalledCounter(), 1);

        // Expect exchange rate to be 1:1 on initial mint
        assertEq(aliceShareAmount, aliceUnderlyingAmount);
        assertEq(vault.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
        assertEq(vault.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
        assertEq(vault.totalSupply(), aliceShareAmount);
        assertEq(vault.totalAssets(), aliceUnderlyingAmount);
        assertEq(vault.balanceOf(alice), aliceUnderlyingAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);

        vm.prank(alice);
        vault.redeem(aliceShareAmount, alice, alice);

        assertEq(vault.beforeWithdrawHookCalledCounter(), 1);

        assertEq(vault.totalAssets(), 0);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal);
    }

    // TODO testMultipleMintDepositRedeemWithdraw

    function testDepositWhenNotEnoughApprovalShouldFail() public {
        underlying.mint(address(this), 0.5e18);
        underlying.approve(address(vault), 0.5e18);

        assertEq(underlying.allowance(address(this), address(vault)), 0.5e18);

        vm.expectRevert("TRANSFER_FROM_FAILED");

        vault.deposit(1e18, address(this));
    }

    function testWithdrawWhenNotEnoughUnderlyingAmountShouldFail() public {
        underlying.mint(address(this), 0.5e18);
        underlying.approve(address(vault), 0.5e18);

        vault.deposit(0.5e18, address(this));

        vm.expectRevert(stdError.arithmeticError);

        vault.withdraw(1e18, address(this), address(this));
    }

    // TODO more sad path tests
}
