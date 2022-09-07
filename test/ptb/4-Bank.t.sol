// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract BankTest is Test {
    //
    Bank bank;

    address DEPOSITOR;

    function setUp() public {
        bank = new Bank();
        deal(DEPOSITOR, 10 ether);
    }

    function test_deposit() public {
        vm.startPrank(DEPOSITOR);
        bank.deposit{value: 1 ether}(1 ether);

        assertEq(DEPOSITOR.balance, 9 ether);
        assertEq(bank.balanceOf(DEPOSITOR), 1 ether);

        bank.deposit{value: 1 ether}(1 ether);

        assertEq(DEPOSITOR.balance, 8 ether);
        assertEq(bank.balanceOf(DEPOSITOR), 2 ether);
    }

    function test_deposit_whenIncorrectAmount_shouldRevert() public {
        vm.expectRevert("Bank: incorrect deposit amount");

        vm.prank(DEPOSITOR);
        bank.deposit{value: 0.9 ether}(1 ether);
    }

    function test_withdraw() public {
        vm.startPrank(DEPOSITOR);
        bank.deposit{value: 2 ether}(2 ether);

        assertEq(DEPOSITOR.balance, 8 ether);
        assertEq(bank.balanceOf(DEPOSITOR), 2 ether);

        bank.withdraw(1 ether);

        assertEq(DEPOSITOR.balance, 9 ether);
        assertEq(bank.balanceOf(DEPOSITOR), 1 ether);
    }

    function test_withdraw_whenMoreThanBalance_shouldRevert() public {
        vm.startPrank(DEPOSITOR);
        bank.deposit{value: 1 ether}(1 ether);

        vm.expectRevert("Bank: not enough funds to cover withdrawal");

        bank.withdraw(2 ether);
    }
}

contract Bank {
    //
    mapping(address => uint256) public balanceOf;

    function deposit(uint256 _amount) public payable {
        require(msg.value == _amount, "Bank: incorrect deposit amount");
        balanceOf[msg.sender] += _amount;
    }

    function withdraw(uint256 _amount) public {
        require(_amount <= balanceOf[msg.sender], "Bank: not enough funds to cover withdrawal");
        balanceOf[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }
}
