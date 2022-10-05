// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// inspired by https://programtheblockchain.com/posts/2018/01/26/what-is-an-ethereum-token/
contract MinimalTokenTest is Test {
    //
    MinimalToken token;

    address deployer = address(0xCAFE);

    function setUp() public {
        vm.prank(deployer);
        token = new MinimalToken(100);
    }

    function test_totalSupply() public {        
        assertEq(token.balanceOf(deployer), 100);
    }

    function test_transfer() public {
        // precondition
        assertEq(token.balanceOf(address(0xABCD)), 0);

        vm.prank(deployer);
        token.transfer(address(0xABCD), 67);

        assertEq(token.balanceOf(address(0xABCD)), 67);
        assertEq(token.balanceOf(deployer), 33);
    }

    function test_transfer_whenInsufficientBalance_shouldRevert() public {
        vm.expectRevert("MinimalToken: insufficient balance for transfer");

        vm.prank(deployer);
        token.transfer(address(0xABCD), 101);
    }

    function test_transfer_whenSubsequentAccounts() public {
        // precondition
        assertEq(token.balanceOf(address(0xBEEF)), 0);

        vm.prank(deployer);
        token.transfer(address(0xABCD), 67);
        vm.prank(address(0xABCD));
        token.transfer(address(0xBEEF), 50);

        assertEq(token.balanceOf(address(0xBEEF)), 50);
        assertEq(token.balanceOf(address(0xABCD)), 17);
        assertEq(token.balanceOf(deployer), 33);
    }
}

contract MinimalToken {
    //
    mapping(address => uint256) public balanceOf;

    constructor (uint256 _totalSupply) {
        balanceOf[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "MinimalToken: insufficient balance for transfer");

        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
    }
}
