// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract SavingsTest is Test {
    //
    Savings savings;

    address OWNER = address(0xBABE);

    uint256 START = 2_000_000_000;
    uint256 DAYS_TO_WAIT = 3;

    function setUp() public {
        vm.warp(START);
        deal(OWNER, 10 ether);

        savings = new Savings(OWNER, DAYS_TO_WAIT);
    }

    function test_deposit() public {
        vm.prank(OWNER);
        savings.deposit{value: 1 ether}(1 ether);

        assertEq(OWNER.balance, 9 ether);
        assertEq(address(savings).balance, 1 ether);
    }

    function test_deposit_whenIncorrectAmount_shouldFail() public {
        vm.expectRevert("Savings: incorrect deposit amount");

        vm.prank(OWNER);
        savings.deposit{value: 1 ether}(2 ether);
    }

    function test_withdraw() public {
        hoax(address(0xABCD), 1 ether); // random EOA
        savings.deposit{value: 1 ether}(1 ether);
        hoax(address(0x1234), 1 ether); // random EOA
        savings.deposit{value: 1 ether}(1 ether);
        vm.startPrank(OWNER);
        savings.deposit{value: 1 ether}(1 ether);

        // precondition checks
        assertEq(OWNER.balance, 9 ether);
        assertEq(address(savings).balance, 3 ether);

        vm.warp(START + 3 days);

        savings.withdraw();

        assertEq(OWNER.balance, 12 ether);
        assertEq(address(savings).balance, 0 ether);
    }

    function test_withdraw_whenNotOwner_shouldFail() public {
        vm.warp(START + 3 days);

        vm.expectRevert("Savings: only owner can do this");

        savings.withdraw();
    }

    function test_withdraw_whenNotEnoughTime_shouldFail() public {        
        vm.startPrank(OWNER);
        savings.deposit{value: 1 ether}(1 ether);

        vm.warp(START + 2 days); // not enough time

        vm.expectRevert("Savings: cannot withdraw yet");

        savings.withdraw();
    }
}

contract Savings {
    //
    address private owner;
    uint256 private deadline;

    modifier onlyOwner() {
        require(msg.sender == owner, "Savings: only owner can do this");
        _;
    }

    constructor (address _owner, uint256 _daysToWait) {
        owner = _owner;
        deadline = block.timestamp + (_daysToWait * 1 days);
    }

    function deposit(uint256 _amount) public payable {
        require(msg.value == _amount, "Savings: incorrect deposit amount");
    }

    function withdraw() public onlyOwner {
        require(block.timestamp >= deadline, "Savings: cannot withdraw yet");
        payable(msg.sender).transfer(address(this).balance);
    }
}
