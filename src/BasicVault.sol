// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "solmate/tokens/ERC20.sol";

contract BasicVault {
    //
    // ERC20 public immutable token;
    // mapping(address => uint256) public balances;
    // event Deposit(address indexed from, uint256 amount);
    // event Withdrawal(address indexed from, uint256 amount);
    // constructor(ERC20 token_) {
    //     token = token_;
    // }
    // function deposit(uint256 amount) external {
    //     balances[msg.sender] += amount;
    //     bool success = token.transferFrom(msg.sender, address(this), amount);
    //     require(success, "Deposit failed!");
    //     emit Deposit(msg.sender, amount);
    // }
    // function withdraw(uint256 amount) external {
    //     balances[msg.sender] -= amount;
    //     bool success = token.transfer(msg.sender, amount);
    //     require(success, "Withdrawal failed!");
    //     emit Withdrawal(msg.sender, amount);
    // }
    // function getBalance(address address_) public returns (uint256 balance) {
    //     return balances[address_];
    // }
}
