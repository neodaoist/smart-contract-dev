// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "solmate/tokens/ERC20.sol";

// inspired by https://jeiwan.net/posts/programming-defi-uniswap-1/
// https://github.com/Jeiwan/zuniswap/tree/part_3/test
contract ExchangeTest is Test {
    //
    Token private token;
    Exchange private exchange;

    address private constant LPer = address(0xCAFE);

    modifier withLiquidity(uint256 _tokenAmount, uint256 _etherAmount) {
        token.approve(address(exchange), _tokenAmount);
        exchange.addLiquidity{value: _etherAmount}(_tokenAmount);
        _;
    }

    function setUp() public {
        startHoax(LPer, 10_000 ether);
        token = new Token("Toke", "TOKE", 10_000e18);
        exchange = new Exchange(address(token));
    }

    /*//////////////////////////////////////////////////////////////
    //  Construction
    //////////////////////////////////////////////////////////////*/

    function test_construction() public {
        assertEq(token.balanceOf(LPer), 10_000e18, "initial trader balance");
        assertEq(token.balanceOf(address(exchange)), 0, "initial exchange balance");

        assertEq(exchange.tokenAddress(), address(token), "token address in exchange");
        assertEq(exchange.factoryAddress(), LPer, "factory address in exchange"); // will be Factory when deployed via Factory

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
        assertEq(token.balanceOf(LPer), 10_000e18, "trader token balance before addLiquidity");
        assertEq(token.balanceOf(address(exchange)), 0, "exchange token balance before addLiquidity");
        assertEq(exchange.getReserve(), 0, "exchange reserve before addLiquidity");
        assertEq(LPer.balance, 10_000 ether, "trader ether balance before addLiquidity");
        assertEq(address(exchange).balance, 0, "exchange ether balance before addLiquidity");
        assertEq(exchange.totalSupply(), 0, "exchange LP tokens before addLiquidity");
        assertEq(exchange.balanceOf(LPer), 0, "LPer LP tokens before addLiquidity");

        token.approve(address(exchange), 2000e18);
        uint256 lpTokens = exchange.addLiquidity{value: 1000 ether}(2000e18);

        assertEq(token.balanceOf(LPer), 8000e18, "trader token balance after addLiquidity");
        assertEq(token.balanceOf(address(exchange)), 2000e18, "exchange token balance before addLiquidity");
        assertEq(exchange.getReserve(), 2000e18, "exchange reserve after addLiquidity");
        assertEq(LPer.balance, 9000 ether, "trader ether balance after addLiquidity");
        assertEq(address(exchange).balance, 1000 ether, "exchange ether balance after addLiquidity");
        assertEq(lpTokens, 1000e18);
        assertEq(exchange.totalSupply(), 1000e18, "exchange LP tokens after addLiquidity");
        assertEq(exchange.balanceOf(LPer), 1000e18, "LPer LP tokens after addLiquidity");
    }

    function test_addLiquidity_whenReservesProporitionAlreadyEstablished() public {
        token.approve(address(exchange), type(uint256).max);
        exchange.addLiquidity{value: 1000 ether}(2000e18);

        assertEq(token.balanceOf(LPer), 8000e18, "trader token balance before addLiquidity");
        assertEq(token.balanceOf(address(exchange)), 2000e18, "exchange token balance before addLiquidity");
        assertEq(exchange.getReserve(), 2000e18, "exchange reserve before addLiquidity");
        assertEq(LPer.balance, 9000 ether, "trader ether balance before addLiquidity");
        assertEq(address(exchange).balance, 1000 ether, "exchange ether balance before addLiquidity");

        // add more liquidity
        uint256 lpTokens = exchange.addLiquidity{value: 1000 ether}(3000e18); // only 2000e18 tokens will be added

        assertEq(token.balanceOf(LPer), 6000e18, "trader token balance after addLiquidity");
        assertEq(token.balanceOf(address(exchange)), 4000e18, "exchange token balance after addLiquidity");
        assertEq(exchange.getReserve(), 4000e18, "exchange reserve after addLiquidity");
        assertEq(LPer.balance, 8000 ether, "trader ether balance after addLiquidity");
        assertEq(address(exchange).balance, 2000 ether, "exchange ether balance after addLiquidity");
        assertEq(lpTokens, 1000e18); // LP tokens issued based only on ether amount added
        assertEq(exchange.totalSupply(), 2000e18, "exchange LP tokens after addLiquidity");
        assertEq(exchange.balanceOf(LPer), 2000e18, "LPer LP tokens after addLiquidity");

        // add even more liquidity
        lpTokens = exchange.addLiquidity{value: 500 ether}(1000e18);

        assertEq(token.balanceOf(LPer), 5000e18, "trader token balance after addLiquidity 2");
        assertEq(token.balanceOf(address(exchange)), 5000e18, "exchange token balance after addLiquidity 2");
        assertEq(exchange.getReserve(), 5000e18, "exchange reserve after addLiquidity 2");
        assertEq(LPer.balance, 7500 ether, "trader ether balance after addLiquidity 2");
        assertEq(address(exchange).balance, 2500 ether, "exchange ether balance after addLiquidity 2");
        assertEq(lpTokens, 500e18);
        assertEq(exchange.totalSupply(), 2500e18, "exchange LP tokens after addLiquidity 2");
        assertEq(exchange.balanceOf(LPer), 2500e18, "LPer LP tokens after addLiquidity 2");
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
        uint256 expectedTokenAmount = (exchange.getReserve() * 1 ether * 99) / ((address(exchange).balance * 100) + (1 ether * 99));
        assertEq(exchange.getTokenAmount(1 ether), expectedTokenAmount, "tokens per ETH");
    }

    function test_getTokenAmount(uint256 etherAmount) public withLiquidity(2000e18, 1000 ether) {
        etherAmount = bound(etherAmount, 1 ether, 1000 ether);

        // uint256 expectedTokenAmount = (exchange.getReserve() * etherAmount) / (address(exchange).balance + etherAmount);
        uint256 expectedTokenAmount = (exchange.getReserve() * etherAmount * 99) / ((address(exchange).balance * 100) + (etherAmount * 99));
        assertEq(exchange.getTokenAmount(etherAmount), expectedTokenAmount, "tokens per ETH");
    }

    function test_getEthAmount() public withLiquidity(2000e18, 1000 ether) {
        uint256 expectedEthAmount = (address(exchange).balance * 2e18 * 99) / ((exchange.getReserve() * 100) + (2e18 * 99));
        assertEq(exchange.getEthAmount(2e18), expectedEthAmount, "ETH per token");
    }

    function test_getEthAmount(uint256 tokenAmount) withLiquidity(2000e18, 1000 ether) public {
        tokenAmount = bound(tokenAmount, 1e18, 2000e18);

        // uint256 expectedEthAmount = (address(exchange).balance * tokenAmount) / (exchange.getReserve() + tokenAmount);
        uint256 expectedEthAmount = (address(exchange).balance * tokenAmount * 99) / ((exchange.getReserve() * 100) + (tokenAmount * 99));
        assertEq(exchange.getEthAmount(tokenAmount), expectedEthAmount, "ETH per token");
    }

    /*//////////////////////////////////////////////////////////////
    //  Swapping
    //////////////////////////////////////////////////////////////*/

    function test_ethToTokenSwap() public withLiquidity(2_000e18, 1_000 ether) {
        uint256 tokenReserve = exchange.getReserve();
        uint256 etherReserve = address(exchange).balance;

        uint256 minTokenAmount = exchange.getTokenAmount(1 ether);
        // uint256 expectedTokenAmount = (tokenReserve * 1 ether) / (etherReserve + 1 ether);
        uint256 expectedTokenAmount = (tokenReserve * 1 ether * 99) / ((etherReserve * 100) + (1 ether * 99));
        assertEq(minTokenAmount, expectedTokenAmount, "tokens per ETH");

        exchange.ethToTokenSwap{value: 1 ether}(minTokenAmount);

        assertEq(token.balanceOf(LPer), 10_000e18 - 2_000e18 + expectedTokenAmount, "trader token balance");
        assertEq(exchange.getReserve(), 2_000e18 - expectedTokenAmount, "exchange reserve");
        assertEq(LPer.balance, 10_000 ether - 1_000 ether - 1 ether, "trader ether balance");
        assertEq(address(exchange).balance, 1_000 ether + 1 ether, "exchange ether balance");
    }

    function test_tokenToEthSwap() public withLiquidity(2_000e18, 1_000 ether) {
        uint256 tokenReserve = exchange.getReserve();
        uint256 etherReserve = address(exchange).balance;
        uint256 tokenToSwap = 1e18;

        uint256 minEtherAmount = exchange.getEthAmount(tokenToSwap);
        // uint256 expectedEtherAmount = (etherReserve * tokenToSwap) / (tokenReserve + tokenToSwap);
        uint256 expectedEtherAmount = (etherReserve * tokenToSwap * 99) / ((tokenReserve * 100) + (tokenToSwap * 99));
        assertEq(minEtherAmount, expectedEtherAmount, "ETH per token");

        token.approve(address(exchange), type(uint256).max);
        exchange.tokenToEthSwap(tokenToSwap, minEtherAmount);

        assertEq(token.balanceOf(LPer), 10_000e18 - 2_000e18 - tokenToSwap, "trader token balance");
        assertEq(exchange.getReserve(), 2_000e18 + tokenToSwap, "exchange reserve");
        assertEq(LPer.balance, 10_000 ether - 1_000 ether + expectedEtherAmount, "trader ether balance");
        assertEq(address(exchange).balance, 1_000 ether - expectedEtherAmount, "exchange ether balance");
    }

    /*//////////////////////////////////////////////////////////////
    //  Removing Liquidity
    //////////////////////////////////////////////////////////////*/

    function test_removeLiquidity() public withLiquidity(2000e18, 1000 ether) {
        // preconditions
        assertEq(exchange.totalSupply(), 1000e18, "LP-token total supply after add liquidity");
        assertEq(exchange.balanceOf(LPer), 1000e18, "LPer LP-token balance before");
        assertEq(address(exchange).balance, 1000 ether, "exchange ether balance before");
        assertEq(LPer.balance, 9000 ether, "LPer ether balance before");
        assertEq(token.balanceOf(address(exchange)), 2000e18, "exchange token balance before");
        assertEq(token.balanceOf(LPer), 8000e18, "LPer token balance before");

        (uint256 ethAmountRemoved, uint256 tokenAmountRemoved) = exchange.removeLiquidity(100e18);

        assertEq(ethAmountRemoved, 100 ether);
        assertEq(tokenAmountRemoved, 200e18);

        assertEq(exchange.totalSupply(), 900e18, "LP-token total supply after add liquidity");
        assertEq(exchange.balanceOf(LPer), 900e18, "LPer LP-token balance after");
        assertEq(address(exchange).balance, 900 ether, "exchange ether balance after");
        assertEq(LPer.balance, 9100 ether, "LPer ether balance after");
        assertEq(token.balanceOf(address(exchange)), 1800e18, "exchange token balance after");
        assertEq(token.balanceOf(LPer), 8200e18, "LPer token balance after");
    }

    function test_removeLiquidity_whenSwapInBetween() public {
        // 1. LPer deposits 100 ether and 200 tokens
        // (therefore 1 token = 0.5 ether and 1 ether = 2 tokens)
        token.approve(address(exchange), type(uint256).max);
        exchange.addLiquidity{value: 100 ether}(200e18);

        assertEq(exchange.totalSupply(), 100e18, "LP-token total supply after add liquidity");
        assertEq(exchange.balanceOf(LPer), 100e18, "LPer LP-token balance after add liquidity");
        assertEq(address(exchange).balance, 100 ether, "exchange ether balance after add liquidity");
        assertEq(LPer.balance, 9900 ether, "LPer ether balance after add liquidity");
        assertEq(token.balanceOf(address(exchange)), 200e18, "exchange token balance after add liquidity");
        assertEq(token.balanceOf(LPer), 9800e18, "LPer token balance after add liquidity");

        // 2. Trader swaps 10 ether for at least 18 tokens
        // (includes slippage and 1% fee)
        vm.stopPrank();
        address trader = address(0xBABE);
        startHoax(trader, 100 ether);
        // deal(address(token), trader, 1_000_000e18);

        exchange.ethToTokenSwap{value: 10 ether}(18e18);

        assertEq(trader.balance, 90 ether, "trader ether balance after swap");
        assertGe(token.balanceOf(trader), 18e18, "trader token balance after swap");
        assertEq(address(exchange).balance, 110 ether, "exchange ether balance after swap");
        assertLe(token.balanceOf(address(exchange)), 200e18 - 18e18, "exchange token balance after swap");
        // emit log_named_uint("trader token balance after swap", token.balanceOf(trader));

        // 3. LPer removes liquidity
        // (getting more ether and less tokens than initially deposited,
        // but all the fees bc they were the only LPer)
        vm.stopPrank();
        vm.startPrank(LPer);
        (uint256 ethAmountRemoved, uint256 tokenAmountRemoved) = exchange.removeLiquidity(100e18);

        assertEq(ethAmountRemoved, 110 ether, "ether amount removed");
        assertApproxEqRel(tokenAmountRemoved, 200e18 - 18e18, 0.0001e18, "token amount removed");

        assertEq(exchange.totalSupply(), 0, "LP-token total supply after remove liquidity");
        assertEq(exchange.balanceOf(LPer), 0, "LPer LP-token balance after remove liquidity");
        assertEq(address(exchange).balance, 0, "exchange ether balance after remove liquidity");
        assertEq(LPer.balance, 10_010 ether, "LPer ether balance after remove liquidity");
        assertEq(token.balanceOf(address(exchange)), 0, "exchange token balance after remove liquidity");
        assertLe(token.balanceOf(LPer), 10_000e18 - 18e18, "LPer token balance after remove liquidity");
    }

    // TODO add test scenario with multiple LPers and multiple swaps

    // TODO add token-to-token swaps
}

contract Exchange is ERC20 {
    //
    error InvalidTokenAddress();
    error InvalidReserves();
    error EthSoldTooSmall();
    error TokenSoldTooSmall();
    error InsufficientTokenAmount();
    error InvalidAmountToRemove();

    address public tokenAddress;
    address public factoryAddress;

    constructor(address _token) ERC20("Zuniswap-V1", "ZUNI-V1", 18) {
        if (_token == address(0)) {
            revert InvalidTokenAddress();
        }
        tokenAddress = _token;
        factoryAddress = msg.sender;
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

    function removeLiquidity(uint256 _amount) public returns (uint256 ethAmountRemoved, uint256 tokenAmountRemoved) {
        if (_amount == 0) {
            revert InvalidAmountToRemove(); // TODO test 
        }

        ethAmountRemoved = (address(this).balance * _amount) / totalSupply;
        tokenAmountRemoved = (getReserve() * _amount) / totalSupply;

        _burn(msg.sender, _amount);

        payable(msg.sender).transfer(ethAmountRemoved);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmountRemoved);
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

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = outputReserve * inputAmountWithFee;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
        // return (outputReserve * inputAmount) / (inputReserve + inputAmount);
    }   
}

////////////////////////////////////////////////////////////////////////////////////////////

contract FactoryTest is Test {
    //
    Token private token;
    Factory private factory;

    address private constant deployer = address(0xCAFE);

    function setUp() public {
        startHoax(deployer, 10_000 ether);
        token = new Token("Toke", "TOKE", 10_000e18);
        factory = new Factory();
    }

    /*//////////////////////////////////////////////////////////////
    //  Create Exchange
    //////////////////////////////////////////////////////////////*/

    function test_createExchange() public {
        address tokenExchange = factory.createExchange(address(token));
        assertFalse(tokenExchange == address(0), "exchange address not zero");
        assertEq(Exchange(tokenExchange).factoryAddress(), address(factory), "factory address set in exchange");
    }

    function testRevert_createExchange_whenTokenAddressIsZero() public {
        vm.expectRevert(Factory.InvalidTokenAddress.selector);
        factory.createExchange(address(0));
    }

    function testRevert_createExchange_whenAlreadyCreatedForTokenAddress() public {
        factory.createExchange(address(token));
        vm.expectRevert(Factory.ExchangeAlreadyCreatedForToken.selector);
        factory.createExchange(address(token));
    }

    /*//////////////////////////////////////////////////////////////
    //  Get Exchange
    //////////////////////////////////////////////////////////////*/

    function test_getExchange() public {
        address exchange = factory.createExchange(address(token));
        assertEq(factory.getExchange(address(token)), exchange);

        assertEq(factory.getExchange(address(0xDEAD)), address(0));
    }
}

contract Factory {
    //
    error InvalidTokenAddress();
    error ExchangeAlreadyCreatedForToken();

    mapping(address => address) public tokenToExchange;

    function createExchange(address _tokenAddress) public returns (address) {
        if (_tokenAddress == address(0)) {
            revert InvalidTokenAddress();
        }
        if (tokenToExchange[_tokenAddress] != address(0)) {
            revert ExchangeAlreadyCreatedForToken();
        }

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);

        return address(exchange);
    }

    function getExchange(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////

contract Token is ERC20 {
    //
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol, 18) {
        _mint(msg.sender, initialSupply);
    }
}
