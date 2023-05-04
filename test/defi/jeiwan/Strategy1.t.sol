// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// inspired by
contract Strategy1Test is Test {
    //
    address constant aaveAddress = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address constant variableDebtWethAddress = 0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;

    Strategy1 strategy;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
        strategy = new Strategy1();
    }

    function testGo() public {
        VariableDebtToken(variableDebtWethAddress).approveDelegation(address(strategy), 2.3 ether);

        strategy.go{value: 1 ether}();

        (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = IAAVE(aaveAddress).getUserAccountData(address(this));

        assertEq(totalCollateralETH, 3.298112774422300227 ether, "total collateral");
        assertEq(totalDebtETH, 2.3 ether, "total debt");
        assertEq(availableBorrowsETH, 0.008678942095610159 ether, "available borrows");
        assertEq(currentLiquidationThreshold, 7500, "current liquidation threshold");
        assertEq(ltv, 7000, "ltv");
        assertEq(healthFactor, 1, "health factor");
    }
}

contract Strategy1 {
    //
    error NotBalancer();
    error NotOwner();

    uint256 constant funds = 1 ether;
    uint256 constant flashLoanFunds = (funds * 230) / 100;

    address constant aaveAddress = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address constant balancerAddress = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant lidoAddress = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address constant stethAddress = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function go() public payable {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        // 1. Take flash loan from Balancer.
        address[] memory tokens = new address[](1);
        tokens[0] = wethAddress;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = flashLoanFunds;

        IBalancer(balancerAddress).flashLoan(address(this), tokens, amounts, "");
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory, /*feeAmounts*/
        bytes memory /*userData*/
    ) public {
        if (msg.sender != balancerAddress) {
            revert NotBalancer();
        }

        // 1a. Unwrap WETH.
        IERC20 loanToken = tokens[0];
        uint256 loanAmount = amounts[0];

        IWETH(wethAddress).withdraw(loanAmount);

        // 2. Stake our ETH plus flash loaned ETH in Lido for stETH.
        ILido(lidoAddress).submit{value: funds + flashLoanFunds}(address(0x0));
        uint256 stethBalance = IERC20(stethAddress).balanceOf(address(this));

        // 3. Deposit the stETH in Aave.
        IERC20(stethAddress).approve(aaveAddress, stethBalance);
        IAAVE(aaveAddress).deposit(stethAddress, stethBalance, owner, 0);

        // 4. Borrow enough WETH from Aave to repay the flash loan (requires owner approval in Aave).
        IAAVE(aaveAddress).borrow(wethAddress, loanAmount, 2, 0, owner);

        // 5. Repay the flash loan.
        loanToken.transfer(balancerAddress, loanAmount);
    }

    receive() external payable {}
}

interface IBalancer {
    function flashLoan(address recipient, address[] memory tokens, uint256[] memory amounts, bytes memory userData)
        external;
}

interface IERC20 {
    function approve(address, uint256) external;

    function balanceOf(address) external returns (uint256);

    function transfer(address, uint256) external;
}

interface IWETH {
    function deposit(uint256) external;

    function withdraw(uint256) external;
}

interface ILido {
    function submit(address) external payable;
}

interface IAAVE {
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function getUserAccountData(address)
        external
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface VariableDebtToken {
    function approveDelegation(address delegatee, uint256 amount) external;
}
