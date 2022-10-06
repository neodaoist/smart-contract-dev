// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {SafeMath} from "openzeppelin/contracts/utils/math/SafeMath.sol";
import {ReentrancyGuard} from "openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Reentrance is ReentrancyGuard {
    //
    using SafeMath for uint256;
    mapping(address => uint) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint balance) {
        return balances[_who];
    }

    function withdraw(uint _amount) public {
        unchecked { // bc >=0.8.0
            if(balances[msg.sender] >= _amount) {
                (bool result, ) = msg.sender.call{value: _amount}("");
                if (result) {
                    _amount;
                }
                balances[msg.sender] -= _amount;
            }
        }
    }

    function withdrawGuarded(uint _amount) public nonReentrant {
        unchecked { // bc >=0.8.0
            if(balances[msg.sender] >= _amount) {
                (bool result, ) = msg.sender.call{value: _amount}("");
                if (result) {
                    _amount;
                }
                balances[msg.sender] -= _amount;
            }
        }
    }

    receive() external payable {}
}

interface IReentrancy {
    function donate(address _to) external payable;
    // function withdraw(uint _amount) external;
    function withdrawGuarded(uint _amount) external;
}

contract ReentrancyPwner {
    //
    IReentrancy public target;
    uint256 initialDeposit;

    constructor(address targetAddress) {
        target = IReentrancy(targetAddress);
    }

    function pwn() external payable {
        require(msg.value >= 0.1 ether, "Send more ether");

        // make initial deposit
        initialDeposit = msg.value;
        target.donate{value: initialDeposit}(address(this));

        // withdraw over and over again
        callWithdraw();
    }

    receive() external payable {
        // reentrance, called by target
        callWithdraw();
    }

    function callWithdraw() private {
        uint256 targetTotalRemainingBalance = address(target).balance;
        bool moreToSteal = targetTotalRemainingBalance > 0;

        if (moreToSteal) {
            uint256 toWithdraw = initialDeposit < targetTotalRemainingBalance
                ? initialDeposit
                : targetTotalRemainingBalance;
            // target.withdraw(toWithdraw);
            target.withdrawGuarded(toWithdraw);
        }  
    }
}

// event 

// modifier nonReentrant

// function view

// function

contract ReentrancyGuardTest is Test {
    //
    Reentrance target;

    address payable a = payable(address(0xA));
    address payable b = payable(address(0xB));
    address payable c = payable(address(0xC));

    function setUp() public {
        target = new Reentrance();
    }

    function testHappyPath() public {
        assertEq(target.balanceOf(a), 0 ether);
        assertEq(target.balanceOf(b), 0 ether);
        assertEq(target.balanceOf(c), 0 ether);

        target.donate{value: 0.1 ether}(a);
        target.donate{value: 0.2 ether}(b);
        hoax(address(0xBABE), 1 ether);
        target.donate{value: 0.1 ether}(c);

        vm.prank(a);
        target.withdraw(0.1 ether);

        vm.prank(b);
        target.withdraw(0.15 ether);

        assertEq(target.balanceOf(a), 0 ether);
        assertEq(target.balanceOf(b), 0.05 ether);
        assertEq(target.balanceOf(c), 0.1 ether);
        assertEq(a.balance, 0.1 ether);
        assertEq(b.balance, 0.15 ether);
        assertEq(c.balance, 0 ether);
    }

    function testReentrancyGuard() public {
        payable(target).transfer(10 ether); // load target w/ ether

        ReentrancyPwner pwner = new ReentrancyPwner(address(target));

        assertEq(address(target).balance, 10 ether);
        assertEq(address(pwner).balance, 0 ether);

        vm.deal(address(pwner), 0.1 ether);
        vm.startPrank(address(pwner));
        pwner.pwn{value: 0.1 ether}();

        assertEq(address(target).balance, 10.1 ether);
        assertEq(address(pwner).balance, 0 ether);
    }
}
