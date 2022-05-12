// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "forge-std/Test.sol";
import "../src/ERC20Contract.sol";

contract ERC20Test is Test {

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    
    using stdStorage for StdStorage;

    ERC20Contract token;

    function setUp() public {
      token = new ERC20Contract("Token", "TKN", 18);
    }

    function testInvariantMetadata() public {
        assertEq(token.name() , "Token");
        assertEq(token.symbol(), "TKN");
        assertEq(token.decimals(), 18);
    }

    ////////////////////////////////////////////////
    ////////////////    XYZ    /////////////////////
    ////////////////////////////////////////////////

    function testMint() public {
        token.mint(address(0xBABE), 1e18);

        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(address(0xBABE)), 1e18);
    }

    function testBurn() public {
        token.mint(address(0xBABE), 1e18);
        token.burn(address(0xBABE), 0.9e18);

        assertEq(token.totalSupply(), 0.1e18);
        assertEq(token.balanceOf(address(0xBABE)), 0.1e18);
    }

    function testApprove() public {
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), address(0xBABE), 1e18);

        assertTrue(token.approve(address(0xBABE), 1e18));
        assertEq(token.allowance(address(this), address(0xBABE)), 1e18);
    }

    function testTransfer() public {
        token.mint(address(this), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0xBABE), 1e18);

        assertTrue(token.transfer(address(0xBABE), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(0xBABE)), 1e18);
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, address(0xBABE), 1e18);

        assertTrue(token.transferFrom(from, address(0xBABE), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.allowance(from, address(this)), 0);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBABE)), 1e18);
    }

}