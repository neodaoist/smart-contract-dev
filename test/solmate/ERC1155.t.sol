// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import "../../src/solmate/ERC1155Contract.sol";

contract ERC1155Test is Test {
    //
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    ERC1155Contract token;

    function setUp() public {
        token = new ERC1155Contract();
    }

    ////////////////////////////////////////////////
    ////////////////    Mint    ////////////////////
    ////////////////////////////////////////////////

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
        assertEq(to.batchIds(), ids);
        assertEq(to.batchAmounts(), amounts);
        assertEq(to.batchData(), "testing 456");

        assertEq(token.balanceOf(address(to), 1337), 100);
        assertEq(token.balanceOf(address(to), 1338), 200);
        assertEq(token.balanceOf(address(to), 1339), 300);
        assertEq(token.balanceOf(address(to), 1340), 400);
        assertEq(token.balanceOf(address(to), 1341), 500);
    }

    function testMintToZeroAddressShouldFail() public {
        vm.expectRevert("UNSAFE_RECIPIENT");

        token.mint(address(0), 1337, 1, "");
    }

    // TODO submit PR to solmate to fix spelling errors in ERC1155.t.sol#L423– (Find [^1]155)

    function testMintToNonERC1155RecipientShouldFail() public {
        address to = address(new NonERC1155Recipient());

        vm.expectRevert();

        token.mint(to, 1337, 1, "");
    }

    function testMintToRevertingERC1155RecipientShouldFail() public {
        address to = address(new RevertingERC1155Recipient());

        vm.expectRevert(bytes(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155Received.selector))));

        token.mint(to, 1337, 1, "");
    }

    function testMintToWrongReturnDataERC1155RecipientShouldFail() public {
        address to = address(new WrongReturnDataERC1155Recipient());

        vm.expectRevert("UNSAFE_RECIPIENT");

        token.mint(to, 1337, 1, "");
    }

    ////////////////////////////////////////////////
    ////////////////    Burn    ////////////////////
    ////////////////////////////////////////////////

    function testBurn() public {
        token.mint(address(0xBABE), 1337, 100, "");

        token.burn(address(0xBABE), 1337, 40);

        assertEq(token.balanceOf(address(0xBABE), 1337), 60);
    }

    function testBatchBurn() public {
        address to = address(0xBABE);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory burnAmounts = new uint256[](5);
        burnAmounts[0] = 40;
        burnAmounts[1] = 80;
        burnAmounts[2] = 120;
        burnAmounts[3] = 160;
        burnAmounts[4] = 200;

        token.batchMint(to, ids, mintAmounts, "");

        token.batchBurn(to, ids, burnAmounts);

        assertEq(token.balanceOf(to, 1337), 60);
        assertEq(token.balanceOf(to, 1338), 120);
        assertEq(token.balanceOf(to, 1339), 180);
        assertEq(token.balanceOf(to, 1340), 240);
        assertEq(token.balanceOf(to, 1341), 300);
    }

    function testFailBurnWhenInsufficientBalance() public {
        token.mint(address(0xBABE), 1337, 40, "");

        //vm.expectRevert("Arithmetic over/underflow"); // TODO research if this is possible

        token.burn(address(0xBABE), 1337, 100);
    }

    ////////////////////////////////////////////////
    ////////////////    Approve    /////////////////
    ////////////////////////////////////////////////

    function testApproveAll() public {
        token.setApprovalForAll(address(0xBABE), true);

        assertTrue(token.isApprovedForAll(address(this), address(0xBABE)));
    }

    // TODO add event tests

    ////////////////////////////////////////////////
    ////////////////    Balance    /////////////////
    ////////////////////////////////////////////////

    function testBatchBalance() public {
        address[] memory addresses = new address[](5);
        addresses[0] = address(0xBEEF);
        addresses[1] = address(0xCAFE);
        addresses[2] = address(0xFACE);
        addresses[3] = address(0xDEAD);
        addresses[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        token.mint(address(0xBEEF), 1337, 100, "");
        token.mint(address(0xCAFE), 1338, 200, "");
        token.mint(address(0xFACE), 1339, 300, "");
        token.mint(address(0xDEAD), 1340, 400, "");
        token.mint(address(0xFEED), 1341, 500, "");

        uint256[] memory balances = token.balanceOfBatch(addresses, ids);

        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
        assertEq(balances[2], 300);
        assertEq(balances[3], 400);
        assertEq(balances[4], 500);
    }

    ////////////////////////////////////////////////
    ////////////////    Transfer    ////////////////
    ////////////////////////////////////////////////

    // TODO add event tests

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(0xBABE), 1337, 40, "");

        assertEq(token.balanceOf(address(0xBABE), 1337), 40);
        assertEq(token.balanceOf(from, 1337), 60);
    }

    function testSafeTransferFromToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(to), 1337, 40, "testing 456");

        assertEq(to.operator(), address(this));
        assertEq(to.from(), from);
        assertEq(to.id(), 1337);
        assertEq(to.mintData(), "testing 456");

        assertEq(token.balanceOf(address(to), 1337), 40);
        assertEq(token.balanceOf(from, 1337), 60);
    }

    function safeTransferFromSelf() public {
        token.mint(address(this), 1337, 100, "");

        token.safeTransferFrom(address(this), address(0xBABE), 1337, 40, "");

        assertEq(token.balanceOf(address(0xBABE), 1337), 40);
        assertEq(token.balanceOf(address(this), 1337), 60);
    }

    function testSafeBatchTransferFromToEOA() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 40;
        transferAmounts[1] = 80;
        transferAmounts[2] = 120;
        transferAmounts[3] = 160;
        transferAmounts[4] = 200;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(0xBABE), ids, transferAmounts, "");

        assertEq(token.balanceOf(from, 1337), 60);
        assertEq(token.balanceOf(address(0xBABE), 1337), 40);

        assertEq(token.balanceOf(from, 1338), 120);
        assertEq(token.balanceOf(address(0xBABE), 1338), 80);

        assertEq(token.balanceOf(from, 1339), 180);
        assertEq(token.balanceOf(address(0xBABE), 1339), 120);

        assertEq(token.balanceOf(from, 1340), 240);
        assertEq(token.balanceOf(address(0xBABE), 1340), 160);

        assertEq(token.balanceOf(from, 1341), 300);
        assertEq(token.balanceOf(address(0xBABE), 1341), 200);
    }

    function testSafeBatchTransferFromToERC1155Recipient() public {
        address from = address(0xABCD);

        ERC1155Recipient to = new ERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 40;
        transferAmounts[1] = 80;
        transferAmounts[2] = 120;
        transferAmounts[3] = 160;
        transferAmounts[4] = 200;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(to), ids, transferAmounts, "testing 456");

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), from);
        assertEq(to.batchIds(), ids);
        assertEq(to.batchAmounts(), transferAmounts);
        assertEq(to.batchData(), "testing 456");

        assertEq(token.balanceOf(from, 1337), 60);
        assertEq(token.balanceOf(address(to), 1337), 40);

        assertEq(token.balanceOf(from, 1338), 120);
        assertEq(token.balanceOf(address(to), 1338), 80);

        assertEq(token.balanceOf(from, 1339), 180);
        assertEq(token.balanceOf(address(to), 1339), 120);

        assertEq(token.balanceOf(from, 1340), 240);
        assertEq(token.balanceOf(address(to), 1340), 160);

        assertEq(token.balanceOf(from, 1341), 300);
        assertEq(token.balanceOf(address(to), 1341), 200);
    }

    function testSafeTransferFromWhenInsufficientBalanceShouldFail() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 60, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert(stdError.arithmeticError);

        token.safeTransferFrom(from, address(0xBABE), 1337, 100, "");
    }

    function testSafeTransferFromSelfWhenInsufficientBalanceShouldFail() public {
        token.mint(address(0xBABE), 1337, 70, "");

        vm.expectRevert(stdError.arithmeticError);

        vm.prank(address(0xBABE));
        token.safeTransferFrom(address(0xBABE), address(0xABCD), 1337, 100, "");
    }

    function testSafeTransferFromToZeroAddressShouldFail() public {
        token.mint(address(0xBABE), 1337, 100, "");

        vm.expectRevert("UNSAFE_RECIPIENT");

        vm.prank(address(0xBABE));
        token.safeTransferFrom(address(0xBABE), address(0), 1337, 60, "");
    }

    function testSafeTransferFromToNonERC1155RecipientShouldFail() public {
        address to = address(new NonERC1155Recipient());

        token.mint(address(0xBABE), 1337, 100, "");

        vm.expectRevert();

        vm.prank(address(0xBABE));
        token.safeTransferFrom(address(0xBABE), to, 1337, 60, "");
    }

    function testSafeTransferFromToRevertingERC1155RecipientShouldFail() public {
        address to = address(new RevertingERC1155Recipient());

        token.mint(address(0xBABE), 1337, 100, "");

        vm.expectRevert(bytes(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155Received.selector))));

        vm.prank(address(0xBABE));
        token.safeTransferFrom(address(0xBABE), to, 1337, 60, "");
    }

    function testSafeTransferFromToWrongDataERC1155RecipientShouldFail() public {
        address to = address(new WrongReturnDataERC1155Recipient());

        token.mint(address(0xBABE), 1337, 100, "");

        vm.expectRevert("NOT_AUTHORIZED");

        vm.prank(address(0xBABE));
        token.safeTransferFrom(address(this), to, 1337, 60, "");
    }

    function testSafeBatchTransferWhenInsufficientBalanceShouldFail() public {
        address from = address(0xABCD);
        address to = address(0xBABE);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 60;
        mintAmounts[1] = 120;
        mintAmounts[2] = 180;
        mintAmounts[3] = 240;
        mintAmounts[4] = 300;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 100;
        transferAmounts[1] = 200;
        transferAmounts[2] = 300;
        transferAmounts[3] = 400;
        transferAmounts[4] = 500;

        token.batchMint(from, ids, mintAmounts, "");

        // Should we exercise this both as self and as approved?
        // Or doesn't matter bc we already exercised both paths

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert(stdError.arithmeticError);

        token.safeBatchTransferFrom(from, to, ids, transferAmounts, "");
    }

    // TODO consider PR to foundry to consolidate to 1 array of amounts when unneeded

    function testSafeBatchTransferFromToZeroAddressShouldFail() public {
        address from = address(0xABCD);

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

        token.batchMint(from, ids, amounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert("UNSAFE_RECIPIENT");

        token.safeBatchTransferFrom(from, address(0), ids, amounts, "");
    }

    function testSafeBatchTransferFromToNonERC1155RecipientShouldFail() public {
        address from = address(0xABCD);
        address to = address(new NonERC1155Recipient());

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

        token.batchMint(from, ids, amounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert();

        token.safeBatchTransferFrom(from, to, ids, amounts, "");
    }

    function testSafeBatchTransferFromToRevertingERC1155RecipientShouldFail() public {
        address from = address(0xABCD);
        address to = address(new RevertingERC1155Recipient());

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

        token.batchMint(from, ids, amounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert(bytes(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155BatchReceived.selector))));

        token.safeBatchTransferFrom(from, to, ids, amounts, "");
    }

    function testSafeBatchTransferFromToWrongReturnDataERC1155RecipientShouldFail() public {
        address from = address(0xABCD);
        address to = address(new WrongReturnDataERC1155Recipient());

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

        token.batchMint(from, ids, amounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert("UNSAFE_RECIPIENT");

        token.safeBatchTransferFrom(from, to, ids, amounts, "");
    }

    function testSafeBatchTransferFromWhenArrayLengthMismatchShouldFail() public {
        address from = address(0xABCD);
        address to = address(0xBABE);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](4);
        transferAmounts[0] = 100;
        transferAmounts[1] = 200;
        transferAmounts[2] = 300;
        transferAmounts[3] = 400;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert("LENGTH_MISMATCH");

        token.safeBatchTransferFrom(from, to, ids, transferAmounts, "");
    }

    function testBatchMintToZeroAddressShouldFail() public {
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

        vm.expectRevert("UNSAFE_RECIPIENT");

        token.batchMint(address(0), ids, amounts, "");
    }

    function testBatchMintToNonERC155RecipientShouldFail() public {
        address to = address(new NonERC1155Recipient());

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

        vm.expectRevert();

        token.batchMint(to, ids, amounts, "");
    }

    function testBatchMintToRevertingERC1155RecipientShouldFail() public {
        address to = address(new RevertingERC1155Recipient());

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

        vm.expectRevert(bytes(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155BatchReceived.selector))));

        token.batchMint(to, ids, amounts, "");
    }

    function testBatchMintToWrongReturnDataERC1155RecipientShouldFail() public {
        address to = address(new WrongReturnDataERC1155Recipient());

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

        vm.expectRevert("UNSAFE_RECIPIENT");

        token.batchMint(to, ids, amounts, "");
    }

    function testBatchMintWhenArrayLengthMismatchShouldFail() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;

        vm.expectRevert("LENGTH_MISMATCH");

        token.batchMint(address(0xBABE), ids, amounts, "");
    }

    function testBatchBurnWhenInsufficientBalanceShouldFail() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 60;
        mintAmounts[1] = 120;
        mintAmounts[2] = 180;
        mintAmounts[3] = 240;
        mintAmounts[4] = 300;

        uint256[] memory burnAmounts = new uint256[](5);
        burnAmounts[0] = 100;
        burnAmounts[1] = 200;
        burnAmounts[2] = 300;
        burnAmounts[3] = 400;
        burnAmounts[4] = 500;

        token.batchMint(address(0xBABE), ids, mintAmounts, "");

        vm.expectRevert(stdError.arithmeticError);

        token.batchBurn(address(0xBABE), ids, burnAmounts);
    }

    function testBatchBurnWhenArrayLengthMismatchShouldFail() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory burnAmounts = new uint256[](4);
        burnAmounts[0] = 100;
        burnAmounts[1] = 200;
        burnAmounts[2] = 300;
        burnAmounts[3] = 400;

        token.batchMint(address(0xBABE), ids, mintAmounts, "");

        vm.expectRevert("LENGTH_MISMATCH");

        token.batchBurn(address(0xBABE), ids, burnAmounts);
    }

    function testBalanceOfBatchWhenArrayLengthMismatchShouldFail() public {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](4);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;

        vm.expectRevert("LENGTH_MISMATCH");

        token.balanceOfBatch(tos, ids);
    }

    // TODO add fuzz tests

    ////////////////////////////////////////////////
    ////////////////    Utility    /////////////////
    ////////////////////////////////////////////////

    // TODO consider PR to foundry to add this assertion
    // CRAP they added it in the latest version! =)

    // function assertEq(uint256[] memory a, uint256[] memory b) internal {
    //     require(a.length == b.length, "Array length mismatch");

    //     for (uint256 i = 0; i < a.length; i++) {
    //         assertEq(a[i], b[i]);
    //     }
    // }
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

contract NonERC1155Recipient {}

contract RevertingERC1155Recipient is ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155Received.selector)));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155BatchReceived.selector)));
    }
}

contract WrongReturnDataERC1155Recipient is ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return 0xCAFEBABE;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xCAFEBABE;
    }
}
