// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract TipJarTest is Test {
    //
    TipJar tipjar;

    address OWNER = address(0xBABE);

    function setUp() public {
        tipjar = new TipJar(OWNER);
        deal(OWNER, 10 ether);
    }

    function test_getBalance() public {
        assertEq(tipjar.getBalance(), 0 ether);
    }

    function test_deposit() public {
        assertEq(tipjar.getBalance(), 0 ether);
        tipjar.deposit{value: 1 ether}(1 ether);
        assertEq(tipjar.getBalance(), 1 ether);
    }

    function test_deposit_whenIncorrectDepositAmount_shouldRevert() public {
        vm.expectRevert("TipJar: incorrect deposit amount");
        tipjar.deposit{value: 0.9 ether}(1 ether);
    }

    function test_withdraw() public {
        uint256 startingBalance = OWNER.balance;

        tipjar.deposit{value: 1 ether}(1 ether);
        assertEq(tipjar.getBalance(), 1 ether);

        vm.prank(OWNER);
        tipjar.withdraw();

        assertEq(tipjar.getBalance(), 0 ether);
        assertEq(OWNER.balance, startingBalance + 1 ether);
    }

    function test_withdraw_whenNotOwner_shouldRevert() public {
        vm.expectRevert("TipJar: only owner can do this");

        tipjar.withdraw();
    }

    function test_changeOwner() public {
        vm.prank(OWNER);
        tipjar.changeOwner(address(0xABCD));

        vm.expectRevert("TipJar: only owner can do this");
        vm.prank(OWNER);
        tipjar.withdraw();

        // no revert
        vm.prank(address(0xABCD));
        tipjar.withdraw();
    }

    function test_changeOwner_whenNotCurrentOwner_shouldRevert() public {
        vm.expectRevert("TipJar: only owner can do this");

        tipjar.changeOwner(address(0xABCD));
    }
}

contract TipJar {
    //
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "TipJar: only owner can do this");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit(uint256 _amount) public payable {
        require(_amount == msg.value, "TipJar: incorrect deposit amount");
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}
