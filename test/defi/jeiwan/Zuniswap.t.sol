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

    /*//////////////////////////////////////////////////////////////
    //  Construction
    //////////////////////////////////////////////////////////////*/

    function test_construction() public {
        assertEq(token.balanceOf(address(0xCAFE)), 10_000e18, "initial trader balance");
        assertEq(token.balanceOf(address(exchange)), 0, "initial exchange balance");

        assertEq(exchange.tokenAddress(), address(token), "token address in exchange");

        assertEq(exchange.name(), "Zuniswap-V1");
        assertEq(exchange.symbol(), "ZUNI-V1");
        assertEq(exchange.decimals(), 18);
    }

    function testRevert_construction_whenTokenIsZeroAddress() public {
        vm.expectRevert(Exchange.InvalidTokenAddress.selector);
        new Exchange(address(0));
    }

    function test_getReserve() public {
        assertEq(exchange.getReserve(), 0, "initial reserve");
    }

    /*//////////////////////////////////////////////////////////////
    //  Adding Liquidity
    //////////////////////////////////////////////////////////////*/

    function test_addLiquidity_whenInitial() public {
        assertEq(token.balanceOf(address(0xCAFE)), 10_000e18, "trader token balance before addLiquidity");
        assertEq(token.balanceOf(address(exchange)), 0, "exchange token balance before addLiquidity");
        assertEq(exchange.getReserve(), 0, "exchange reserve before addLiquidity");
        assertEq(address(0xCAFE).balance, 10_000 ether, "trader ether balance before addLiquidity");
        assertEq(address(exchange).balance, 0, "exchange ether balance before addLiquidity");
        assertEq(exchange.totalSupply(), 0, "exchange LP tokens before addLiquidity");
        assertEq(exchange.balanceOf(address(0xCAFE)), 0, "LPer LP tokens before addLiquidity");

        token.approve(address(exchange), 2000e18);
        uint256 lpTokens = exchange.addLiquidity{value: 1000 ether}(2000e18);

        assertEq(token.balanceOf(address(0xCAFE)), 8000e18, "trader token balance after addLiquidity");
        assertEq(token.balanceOf(address(exchange)), 2000e18, "exchange token balance before addLiquidity");
        assertEq(exchange.getReserve(), 2000e18, "exchange reserve after addLiquidity");
        assertEq(address(0xCAFE).balance, 9000 ether, "trader ether balance after addLiquidity");
        assertEq(address(exchange).balance, 1000 ether, "exchange ether balance after addLiquidity");
        assertEq(lpTokens, 1000e18);
        assertEq(exchange.totalSupply(), 1000e18, "exchange LP tokens after addLiquidity");
        assertEq(exchange.balanceOf(address(0xCAFE)), 1000e18, "LPer LP tokens after addLiquidity");
    }

    function test_addLiquidity_whenReservesProporitionAlreadyEstablished() public {
        token.approve(address(exchange), type(uint256).max);
        exchange.addLiquidity{value: 1000 ether}(2000e18);

        assertEq(token.balanceOf(address(0xCAFE)), 8000e18, "trader token balance before addLiquidity");
        assertEq(token.balanceOf(address(exchange)), 2000e18, "exchange token balance before addLiquidity");
        assertEq(exchange.getReserve(), 2000e18, "exchange reserve before addLiquidity");
        assertEq(address(0xCAFE).balance, 9000 ether, "trader ether balance before addLiquidity");
        assertEq(address(exchange).balance, 1000 ether, "exchange ether balance before addLiquidity");

        // add more liquidity
        uint256 lpTokens = exchange.addLiquidity{value: 1000 ether}(3000e18); // only 2000e18 tokens will be added

        assertEq(token.balanceOf(address(0xCAFE)), 6000e18, "trader token balance after addLiquidity");
        assertEq(token.balanceOf(address(exchange)), 4000e18, "exchange token balance after addLiquidity");
        assertEq(exchange.getReserve(), 4000e18, "exchange reserve after addLiquidity");
        assertEq(address(0xCAFE).balance, 8000 ether, "trader ether balance after addLiquidity");
        assertEq(address(exchange).balance, 2000 ether, "exchange ether balance after addLiquidity");
        assertEq(lpTokens, 1000e18); // LP tokens issued based only on ether amount added
        assertEq(exchange.totalSupply(), 2000e18, "exchange LP tokens after addLiquidity");
        assertEq(exchange.balanceOf(address(0xCAFE)), 2000e18, "LPer LP tokens after addLiquidity");

        // add even more liquidity
        lpTokens = exchange.addLiquidity{value: 500 ether}(1000e18);

        assertEq(token.balanceOf(address(0xCAFE)), 5000e18, "trader token balance after addLiquidity 2");
        assertEq(token.balanceOf(address(exchange)), 5000e18, "exchange token balance after addLiquidity 2");
        assertEq(exchange.getReserve(), 5000e18, "exchange reserve after addLiquidity 2");
        assertEq(address(0xCAFE).balance, 7500 ether, "trader ether balance after addLiquidity 2");
        assertEq(address(exchange).balance, 2500 ether, "exchange ether balance after addLiquidity 2");
        assertEq(lpTokens, 500e18);
        assertEq(exchange.totalSupply(), 2500e18, "exchange LP tokens after addLiquidity 2");
        assertEq(exchange.balanceOf(address(0xCAFE)), 2500e18, "LPer LP tokens after addLiquidity 2");
    }

    function testRevert_addLiquidity_whenInsufficientApproval() public {
        vm.expectRevert(stdError.arithmeticError);
        exchange.addLiquidity(10e18);
    }

    function testRevert_addLiquidity_whenInsufficientTokenAmount() public {
        token.approve(address(exchange), type(uint256).max);
        exchange.addLiquidity{value: 1000 ether}(2000e18);

        vm.expectRevert(Exchange.InsufficientTokenAmount.selector);

        exchange.addLiquidity{value: 500 ether}(500e18);
    }

    /*//////////////////////////////////////////////////////////////
    //  Getting Prices
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
    //  Swapping
    //////////////////////////////////////////////////////////////*/

    function test_ethToTokenSwap() public withLiquidity(2_000e18, 1_000 ether) {
        uint256 tokenReserve = exchange.getReserve();
        uint256 etherReserve = address(exchange).balance;

        uint256 minTokenAmount = exchange.getTokenAmount(1 ether);
        uint256 expectedTokenAmount = (tokenReserve * 1 ether) / (etherReserve + 1 ether);
        assertEq(minTokenAmount, expectedTokenAmount, "tokens per ETH");

        exchange.ethToTokenSwap{value: 1 ether}(minTokenAmount);

        assertEq(token.balanceOf(address(0xCAFE)), 10_000e18 - 2_000e18 + expectedTokenAmount, "trader token balance");
        assertEq(exchange.getReserve(), 2_000e18 - expectedTokenAmount, "exchange reserve");
        assertEq(address(0xCAFE).balance, 10_000 ether - 1_000 ether - 1 ether, "trader ether balance");
        assertEq(address(exchange).balance, 1_000 ether + 1 ether, "exchange ether balance");
    }

    function test_tokenToEthSwap() public withLiquidity(2_000e18, 1_000 ether) {
        uint256 tokenReserve = exchange.getReserve();
        uint256 etherReserve = address(exchange).balance;
        uint256 tokenToSwap = 1e18;

        uint256 minEtherAmount = exchange.getEthAmount(tokenToSwap);
        uint256 expectedEtherAmount = (etherReserve * tokenToSwap) / (tokenReserve + tokenToSwap);
        assertEq(minEtherAmount, expectedEtherAmount, "ETH per token");

        token.approve(address(exchange), type(uint256).max);
        exchange.tokenToEthSwap(tokenToSwap, minEtherAmount);

        assertEq(token.balanceOf(address(0xCAFE)), 10_000e18 - 2_000e18 - tokenToSwap, "trader token balance");
        assertEq(exchange.getReserve(), 2_000e18 + tokenToSwap, "exchange reserve");
        assertEq(address(0xCAFE).balance, 10_000 ether - 1_000 ether + expectedEtherAmount, "trader ether balance");
        assertEq(address(exchange).balance, 1_000 ether - expectedEtherAmount, "exchange ether balance");
    }
}

contract Exchange is ERC20 {
    //
    error InvalidTokenAddress();
    error InvalidReserves();
    error EthSoldTooSmall();
    error TokenSoldTooSmall();
    error InsufficientTokenAmount();

    address public tokenAddress;

    constructor(address _token) ERC20("Zuniswap-V1", "ZUNI-V1", 18) {
        if (_token == address(0)) {
            revert InvalidTokenAddress();
        }
        tokenAddress = _token;
    }

    function addLiquidity(uint256 _tokenAmount) public payable returns (uint256) {
        if (getReserve() == 0) {
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);

            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);  

            return liquidity;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            if (_tokenAmount < tokenAmount) {
                revert InsufficientTokenAmount();
            }

            uint256 liquidity = (totalSupply * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);

            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), tokenAmount);

            return liquidity;
        }
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

    function tokenToEthSwap(uint256 _tokensSwapped, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethSwapped = _getAmount(_tokensSwapped, tokenReserve, address(this).balance);

        if (ethSwapped < _minEth) {
            // TODO revert
        }

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokensSwapped);
        payable(msg.sender).transfer(ethSwapped);        
    }

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
