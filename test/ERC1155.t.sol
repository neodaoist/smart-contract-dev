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

    function testBatchMintToEOA() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        token.batchMint(address(0xBABE), ids, amounts, "");

        assertEq(token.balanceOf(address(0xBABE), 1337), 100);
        assertEq(token.balanceOf(address(0xBABE), 1338), 200);
        assertEq(token.balanceOf(address(0xBABE), 1339), 300);
        assertEq(token.balanceOf(address(0xBABE), 1340), 400);
        assertEq(token.balanceOf(address(0xBABE), 1341), 500);
    }

    function testBatchMintToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        token.batchMint(address(to), ids, amounts, "testing 456");

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), address(0));
        // assertUintArrayEq(to.batchIds(), ids);
        for (uint i = 0; i < ids.length; i++) {
            assertEq(to.batchIds()[i], ids[i]);
        }
        // assertUintArrayEq(to.batchAmounts(), amounts);
        for (uint j = 0; j < amounts.length; j++) {
            assertEq(to.batchAmounts()[j], amounts[j]);
        }
        assertEq(to.batchData(), "testing 456");

        assertEq(token.balanceOf(address(to), 1337), 100);
        assertEq(token.balanceOf(address(to), 1338), 200);
        assertEq(token.balanceOf(address(to), 1339), 300);
        assertEq(token.balanceOf(address(to), 1340), 400);
        assertEq(token.balanceOf(address(to), 1341), 500);
    }

    function testBurn() public {
        token.mint(address(0xBABE), 1337, 100, "");

        token.burn(address(0xBABE), 1337, 70);

        assertEq(token.balanceOf(address(0xBABE), 1337), 30);
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

    address public batchOperator;
    address public batchFrom;
    uint256[] internal _batchIds;
    uint256[] internal _batchAmounts;
    bytes public batchData;

    function batchIds() external view returns (uint256[] memory) {
        return _batchIds;
    }

    function batchAmounts() external view returns (uint256[] memory) {
        return _batchAmounts;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external override returns (bytes4) {
        batchOperator = _operator;
        batchFrom = _from;
        _batchIds = _ids;
        _batchAmounts = _amounts;
        batchData = _data;

        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}
