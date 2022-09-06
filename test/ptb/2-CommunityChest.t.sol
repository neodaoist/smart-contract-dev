// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract CommunityChestTest is Test {
    //
    CommunityChest chest;

    function setUp() public {
        chest = new CommunityChest();
    }

    function test_getBalance() public {
        assertEq(chest.getBalance(), 0 ether);
    }

    function test_deposit() public {
        assertEq(chest.getBalance(), 0 ether);
        chest.deposit{value: 1 ether}(1 ether);
        assertEq(chest.getBalance(), 1 ether);
    }

    function test_deposit_whenIncorrectDepositAmount_shouldRevert() public {
        vm.expectRevert("CommunityChest: incorrect deposit amount");
        chest.deposit{value: 0.9 ether}(1 ether);
    }

    function test_withdraw() public {
        startHoax(address(0xBABE), 10 ether);

        chest.deposit{value: 1 ether}(1 ether);
        assertEq(chest.getBalance(), 1 ether);
        assertEq(address(0xBABE).balance, 9 ether);

        chest.withdraw();

        assertEq(chest.getBalance(), 0 ether);
        assertEq(address(0xBABE).balance, 10 ether);
    }
}

contract CommunityChest {
    //
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit(uint256 _amount) public payable {
        require(_amount == msg.value, "CommunityChest: incorrect deposit amount");
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}
