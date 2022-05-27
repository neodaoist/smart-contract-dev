// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "forge-std/Test.sol";
import "../src/ERC1155Contract.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

contract ERC1155Test is Test {

    ERC1155Contract token;

    function setUp() public {
      token = new ERC1155Contract();
    }

    function testMintToEOA() public {
        token.mint(address(0xBABE), 1337, 1, "");

        assertEq(token.balanceOf(address(0xBABE), 1337), 1);
    }

    function testMintToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        token.mint(address(to), 1337, 1, "testing 456");

        assertEq(token.balanceOf(address(to), 1337), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertEq(to.mintData(), "testing 456");
    }

    //

}

contract ERC1155Recipient is ERC1155TokenReceiver {

    address public operator;
    address public from;
    uint256 public id;
    uint256 public amount;
    bytes public mintData;

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        amount = _amount;
        mintData = _data;

        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    //

}
