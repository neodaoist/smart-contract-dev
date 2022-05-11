// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'solmate/tokens/ERC20.sol';

contract LeetToken is ERC20 {
    constructor() ERC20('Leet Token', 'LEET', 18) {}
}

contract BasicVault {
    LeetToken public immutable leetToken;
    mapping(address => uint) public balances;

    event Deposit(address indexed from, uint amount);
    event Withdrawal(address indexed from, uint amount);

    constructor(LeetToken leetToken_) {
        leetToken = leetToken_;
    }

    function deposit(uint amount) external {
        balances[msg.sender] += amount;

        bool success = leetToken.transferFrom(msg.sender, address(this), amount);
        require(success, 'Deposit failed!');

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint amount) external {
        balances[msg.sender] -= amount;

        bool success = leetToken.transfer(msg.sender, amount);
        require(success, 'Withdrawal failed!');

        emit Withdrawal(msg.sender, amount);
    }
}
