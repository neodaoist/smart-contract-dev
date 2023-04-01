// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";

/**

Feature: Cash-secured Wrapped Ether

    As an Option Market Maker,
    I want to use USDC to collateralize my ETH puts,
    so that I can achieve higher capital efficiency and simplify my PNL accounting.

    Scenario: Deposit USDC into vault
        Given I have 1,000,000 USDC in my wallet
        And The current price of ETH is 1,800 USDC
        And The cashWETH vault total assets is 0 USDC
        When I deposit 1,800 USDC into the cashWETH vault
        Then I should have 998,200 USDC in my wallet
        And I should have 1 cashWETH share in my wallet (balanceOf)
        And I should be able to withdraw 1,800 USDC assets for my 1 cashWETH share (previewWithdraw)
        And The cashWETH vault total assets is 1,800 USDC

    Scenario: Withdraw USDC from vault
        Given I have 1 cashWETH share in my wallet
        And The current price of ETH is 1,800 USDC
        And The cashWETH vault total assets is 1,800 USDC
        When I withdraw 1,800 USDC from the cashWETH vault
        Then I should have 1,000,000 USDC in my wallet
        And I should have 0 cashWETH shares in my wallet
        And The cashWETH vault total assets should be 0 USDC

    Scenario: Withdraw WETH from vault
        Given TODO

    Scenario: Transfer to another address and withdraw USDC from vault
        Given TODO

    Scenario: Transfer to another address and withdraw WETH from vault
        Given TODO

    Scenario: Rebalance vault when ETH price increases
        Given I have 998,200 USDC in my wallet
        And I have 1 cashWETH share in my wallet
        And The cashWETH vault total assets is 1,800 USDC
        When The price of ETH increases to 2,000 USDC
        Then I should have 998,000 USDC in my wallet
        And I should be able to withdraw 2,000 USDC assets for my 1 cashWETH share (previewWithdraw)
        And The cashWETH vault total assets should be 2,000 USDC

    Scenario: Rebalance vault when ETH price decreases
        Given I have 998,200 USDC in my wallet
        And I have 1 cashWETH share in my wallet
        And The cashWETH vault total assets is 1,800 USDC
        When The price of ETH decreases to 1,600 USDC
        Then I should have 998,400 USDC in my wallet
        And I should be able to withdraw 1,600 USDC assets for my 1 cashWETH share (previewWithdraw)
        And The cashWETH vault total assets should be 1,600 USDC

    @Revert
    Scenario: Rebalance vault when ETH price decreases, insufficient balance
        Given TODO

    @Revert
    Scenario: Rebalance vault when ETH price decreases, insufficient allowance
        Given TODO

 */

contract cashWETHTest is Test {
    //
    IWETH internal weth;
    ChainlinkOracle internal oracleEthUsd;
    CashWETH internal cashWETH;

    uint256 internal constant BLOCK = 16_957_534;

    address internal constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CHAINLINK_ETHUSD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), BLOCK);

        weth = IWETH(WETH9);
        oracleEthUsd = ChainlinkOracle(CHAINLINK_ETHUSD);
        cashWETH = new CashWETH(weth, oracleEthUsd);
    }

    function testInitial() public {
        assertEq(cashWETH.name(), "Cash-secured Wrapped Ether", "ERC4626 name");
        assertEq(cashWETH.symbol(), "cashWETH", "ERC4626 symbol");
        assertEq(cashWETH.decimals(), 18, "ERC4626 decimals");
        assertEq(address(cashWETH.asset()), address(weth), "ERC4626 asset");
        assertEq(address(cashWETH.oracleEthUsd()), address(oracleEthUsd), "ERC4626 oracle");
    }

    function testOracle() public {
        (, int256 answer, , uint256 updatedAt, ) = oracleEthUsd.latestRoundData();
        assertApproxEqRel(answer, 182_403_000_000, 0.1e18, "oracleEthUsd latest answer");
        assertApproxEqRel(updatedAt, 1_680_389_735, 0.1e18, "oracleEthUsd latest updatedAt");
    }

    // TODO
    
}

/// @title cashWETH, rhymes with "hashish"
contract CashWETH is ERC4626 {
    //
    ChainlinkOracle public oracleEthUsd;

    constructor(IWETH _weth, ChainlinkOracle _oracleEthUsd) ERC4626(ERC20(address(_weth)), "Cash-secured Wrapped Ether", "cashWETH") {
        oracleEthUsd = _oracleEthUsd;
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }
}

interface IWETH {
    function deposit() external payable;
    function balanceOf(address) external view returns (uint256);
}

interface ChainlinkOracle {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
