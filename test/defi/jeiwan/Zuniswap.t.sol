// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "solmate/tokens/ERC20.sol";

// inspired by https://jeiwan.net/posts/programming-defi-uniswap-1/
contract ExchangeTest is Test {
    //
    Token internal token;
    Exchange internal exchange;

    modifier withLiquidity(uint256 _tokenAmount, uint256 _etherAmount) {
        token.approve(address(exchange), _tokenAmount);
        exchange.addLiquidity{value: _etherAmount}(_tokenAmount);
        _;
    }

    function setUp() public {
        startHoax(address(0xCAFE), 10_000 ether);
        token = new Token("Toke", "TOKE", 10_000e18);
        exchange = new Exchange(address(token));
    }

    function test_construction() public {
        assertEq(token.balanceOf(address(0xCAFE)), 10_000e18, "initial trader balance");
        assertEq(token.balanceOf(address(exchange)), 0, "initial exchange balance");
        assertEq(exchange.tokenAddress(), address(token), "token address in exchange");
    }

    function testRevert_construction_whenTokenIsZeroAddress() public {
        vm.expectRevert(Exchange.InvalidTokenAddress.selector);
        new Exchange(address(0));
    }

    function test_getReserve() public {
        assertEq(exchange.getReserve(), 0, "initial reserve");
    }

    function test_addLiquidity() public {
        assertEq(token.balanceOf(address(0xCAFE)), 10_000e18, "trader token balance before addLiquidity");
        assertEq(token.balanceOf(address(exchange)), 0, "exchange token balance before addLiquidity");
        assertEq(exchange.getReserve(), 0, "exchange reserve before addLiquidity");
        assertEq(address(0xCAFE).balance, 10_000 ether, "trader ether balance before addLiquidity");
        assertEq(address(exchange).balance, 0, "exchange ether balance before addLiquidity");

        token.approve(address(exchange), 2000e18);
        exchange.addLiquidity{value: 1000 ether}(2000e18);

        assertEq(token.balanceOf(address(0xCAFE)), 8000e18, "trader token balance after addLiquidity");
        assertEq(token.balanceOf(address(exchange)), 2000e18, "exchange token balance before addLiquidity");
        assertEq(exchange.getReserve(), 2000e18, "exchange reserve after addLiquidity");
        assertEq(address(0xCAFE).balance, 9000 ether, "trader ether balance after addLiquidity");
        assertEq(address(exchange).balance, 1000 ether, "exchange ether balance after addLiquidity");
    }

    function testRevert_addLiquidity_whenNotSufficientApproval() public {
        vm.expectRevert(stdError.arithmeticError);
        exchange.addLiquidity(10e18);
    }

    function test_getPrice() public withLiquidity(2000e18, 1000 ether) {
        uint256 tokenReserve = exchange.getReserve();
        uint256 etherReserve = address(exchange).balance;

        assertEq(exchange.getPrice(etherReserve, tokenReserve), 500, "ETH per token");
        assertEq(exchange.getPrice(tokenReserve, etherReserve), 2000, "tokens per ETH");
    }

    function test_getTokenAmount() public withLiquidity(2000e18, 1000 ether) {
        assertEq(exchange.getTokenAmount(1 ether), 1998001998001998001, "tokens per ETH");
    }

    function test_getTokenAmount(uint256 etherAmount) public withLiquidity(2000e18, 1000 ether) {
        etherAmount = bound(etherAmount, 1 ether, 1000 ether);

        uint256 expectedTokenAmount = (exchange.getReserve() * etherAmount) / (address(exchange).balance + etherAmount);
        assertEq(exchange.getTokenAmount(etherAmount), expectedTokenAmount, "tokens per ETH");
    }

    function test_getEthAmount() public withLiquidity(2000e18, 1000 ether) {
        assertEq(exchange.getEthAmount(2e18), 999000999000999000, "ETH per token");
    }

    function test_getEthAmount(uint256 tokenAmount) withLiquidity(2000e18, 1000 ether) public {
        tokenAmount = bound(tokenAmount, 1e18, 2000e18);

        uint256 expectedEthAmount = (address(exchange).balance * tokenAmount) / (exchange.getReserve() + tokenAmount);
        assertEq(exchange.getEthAmount(tokenAmount), expectedEthAmount, "ETH per token");
    }

    function test_ethToTokenSwap() public withLiquidity(2_000e18, 1_000 ether) {
        uint256 tokenReserve = exchange.getReserve();
        uint256 etherReserve = address(exchange).balance;

        uint256 minTokenAmount = exchange.getTokenAmount(1 ether);
        uint256 expectedTokenAmount = (tokenReserve * 1 ether) / (etherReserve + 1 ether);
        assertEq(minTokenAmount, expectedTokenAmount, "tokens per ETH");

        token.approve(address(exchange), minTokenAmount);
        exchange.ethToTokenSwap{value: 1 ether}(minTokenAmount);

        assertEq(token.balanceOf(address(0xCAFE)), 10_000e18 - 2_000e18 + expectedTokenAmount, "trader token balance");
        assertEq(exchange.getReserve(), 2_000e18 - expectedTokenAmount, "exchange reserve");
        assertEq(address(0xCAFE).balance, 10_000 ether - 1_000 ether - 1 ether, "trader ether balance");
        assertEq(address(exchange).balance, 1_000 ether + 1 ether, "exchange ether balance");
    }
}

contract Exchange {
    //
    error InvalidTokenAddress();
    error InvalidReserves();
    error EthSoldTooSmall();
    error TokenSoldTooSmall();

    address public tokenAddress;

    constructor(address _token) {
        if (_token == address(0)) {
            revert InvalidTokenAddress();
        }
        tokenAddress = _token;
    }

    function addLiquidity(uint256 _tokenAmount) public payable {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
    }

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getPrice(uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        if (inputReserve == 0 || outputReserve == 0) {
            revert InvalidReserves(); // TODO test
        }

        return (inputReserve * 1000) / outputReserve;
    }

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        if (_ethSold == 0) {
            revert EthSoldTooSmall(); // TODO test
        }

        uint256 tokenReserve = getReserve();

        return _getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        if (_tokenSold == 0) {
            revert TokenSoldTooSmall(); // TODO test
        }

        uint256 tokenReserve = getReserve();

        return _getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensSwapped = _getAmount(msg.value, address(this).balance - msg.value, tokenReserve);

        if (tokensSwapped < _minTokens) {
            // TODO revert
        }

        IERC20(tokenAddress).transfer(msg.sender, tokensSwapped);
    }

    // function tokenToEthSwap(uint256 _tokensSwapped, uint256 _minEth) public {
    //     uint256 tokenReserve = getReserve();
    //     uint256 ethSwapped = _getAmount(_tokensSwapped, tokenReserve, address(this).balance);

    //     if (ethSwapped < _minEth) {
    //         // TODO revert
    //     }

    //     IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokensSwapped);
    //     payable(msg.sender).transfer(ethSwapped);        
    // }

    function _getAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) private pure returns (uint256) {
        if (inputReserve == 0 || outputReserve == 0) {
            revert InvalidReserves(); // TODO test
        }

        return (outputReserve * inputAmount) / (inputReserve + inputAmount);
    }   
}

contract Token is ERC20 {
    //
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol, 18) {
        _mint(msg.sender, initialSupply);
    }
}
