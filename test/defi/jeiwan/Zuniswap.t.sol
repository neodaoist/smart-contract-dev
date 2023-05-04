// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "solmate/tokens/ERC20.sol";

// inspired by https://jeiwan.net/posts/programming-defi-uniswap-1/
contract ExchangeTest is Test {
    //
    Token internal toke;
    Exchange internal exchange;

    function setUp() public {
        startHoax(address(0xCAFE), 10 ether);
        toke = new Token("Toke", "TOKE", 1000e18);
        exchange = new Exchange(address(toke));
    }

    function test_construction() public {
        assertEq(toke.balanceOf(address(0xCAFE)), 1000e18, "initial trader balance");
        assertEq(toke.balanceOf(address(exchange)), 0, "initial exchange balance");
        assertEq(exchange.tokenAddress(), address(toke), "token address in exchange");
    }

    function testRevert_construction_whenTokenIsZeroAddress() public {
        vm.expectRevert(Exchange.InvalidTokenAddress.selector);
        Exchange exchange = new Exchange(address(0));
    }

    function test_addLiquidity() public {
        assertEq(toke.balanceOf(address(0xCAFE)), 1000e18, "trader token balance before addLiquidity");
        assertEq(toke.balanceOf(address(exchange)), 0, "exchange token balance before addLiquidity");
        assertEq(address(0xCAFE).balance, 10 ether, "trader ether balance before addLiquidity");
        assertEq(address(exchange).balance, 0, "exchange ether balance before addLiquidity");

        toke.approve(address(exchange), 200e18);
        exchange.addLiquidity{value: 1 ether}(200e18);

        assertEq(toke.balanceOf(address(0xCAFE)), 800e18, "trader token balance after addLiquidity");
        assertEq(exchange.getReserve(), 200e18, "exchange token balance after addLiquidity");
        assertEq(address(0xCAFE).balance, 9 ether, "trader ether balance after addLiquidity");
        assertEq(address(exchange).balance, 1 ether, "exchange ether balance after addLiquidity");
    }

    function testRevert_addLiquidity_whenNotSufficientApproval() public {
        vm.expectRevert(stdError.arithmeticError);
        exchange.addLiquidity(10e18);
    }

    // Now, lets think about how we would calculate exchange prices.

}

contract Exchange {
    //
    error InvalidTokenAddress();

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
}

contract Token is ERC20 {
    //
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol, 18) {
        _mint(msg.sender, initialSupply);
    }
}
