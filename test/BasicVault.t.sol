// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "forge-std/Test.sol";
import "../src/BasicVault.sol";

contract LeetToken is ERC20 {
    //
    constructor() ERC20("Leet Token", "LEET", 18) {}

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}

// contract BasicVaultTest is Test {

//     LeetToken token;
//     BasicVault vault;

//     constructor() {
//         token = new LeetToken();
//         vault = new BasicVault(token);
//     }

//     function testDeposit() public {
//         token.mint(address(0xBABE), 1338);
//         assertEq(token.balanceOf(address(0xBABE)), 1338);

//         vm.prank(address(0xBABE));
//         vault.deposit(1337);

//         assertEq(token.balanceOf(address(0xBABE)), 1);
//         assertEq(vault.getBalance(address(0xBABE)), 1337);
//     }

//     function testUserCannotWithdrawExcessOfDeposit() public {
//         vm.prank(address(0xBABE));
//         vm.expectRevert(stdError.arithmeticError);

//         vault.withdraw(100*10**18);
//     }
// }
