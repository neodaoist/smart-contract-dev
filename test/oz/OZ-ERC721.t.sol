// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {IERC721Receiver} from "openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {ERC721Contract} from "../../src/oz/ERC721Contract.sol";

contract ERC721Test is Test {
    //
    ERC721Contract token;

    address owner = address(0xBABE);
    address rando = address(0xABCD);
    address to = address(0xCAFE);
    address approved = address(0xDEAD);
    address operator = address(0xBEEF);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setUp() public {
        token = new ERC721Contract();
    }

    function testInvariantMetadata() public {
        assertEq(token.name(), "Epique NFT");
        assertEq(token.symbol(), "EPIQUE");
    }

    /*//////////////////////////////////////////////////////////////
                        Test Helpers
    //////////////////////////////////////////////////////////////*/

    function givenMintedTokens() internal {
        token.mint(owner, 123);
        token.mint(owner, 456);
    }

    function andSetupApprovals() internal {
        vm.startPrank(owner);
        token.approve(approved, 123);
        token.setApprovalForAll(operator, true);
        vm.stopPrank();
    }

    function thenTransferWasSuccessful(
        address from_,
        address to_,
        uint256 tokenID_
    ) internal {
        // transfers the ownership of the given token ID to the given address
        assertEq(token.ownerOf(tokenID_), to_);

        // emits a Transfer event
        // vm.expectEmit(true, true, true, true);
        // emit Transfer(owner, to, 123);

        // clears the approval for the token ID
        assertEq(token.getApproved(123), address(0));

        // emits an Approval event
        // vm.expectEmit(true, true, true, true);
        // emit Approval(owner, address(0), 123);

        // adjusts owners balances
        assertEq(token.balanceOf(owner), 1);
        assertEq(token.balanceOf(to), 1);

        // adjusts owners tokens by index
        assertEq(token.ownerOf(123), to);
    }

    function thenTransferWasSuccessful_events(
        address from_,
        address to_,
        uint256 tokenID_
    ) internal {
        // need to expect these logs in reverse order

        // emits an Approval event
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, address(0), 123);

        // emits a Transfer event
        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, to, 123);
    }

    // function shouldTransferTokensByUsers() {

    // }

    function shouldSafeTransferTokensByUsers(
        address from_,
        address to_,
        uint256 tokenID_
    ) internal {
        // When called by owner
        token.safeTransferFrom(from_, to_, tokenID_);
        thenTransferWasSuccessful(from_, to_, tokenID_);

        // When called by approved account
        vm.prank(approved);
        token.safeTransferFrom(from_, to_, tokenID_);
    }

    /*//////////////////////////////////////////////////////////////
                        Interface tests
    //////////////////////////////////////////////////////////////*/

    // TODO add ERC165 and ERC721 interface tests

    /*//////////////////////////////////////////////////////////////
                        balanceOf
    //////////////////////////////////////////////////////////////*/

    function testBalanceOf_whenAddressOwnsTokens_thenReturnCorrectAmountOfTokens() public {
        givenMintedTokens();

        assertEq(token.balanceOf(owner), 2);
    }

    function testBalanceOf_whenAddressDoesNotOwnTokens_thenReturn0() public {
        givenMintedTokens();

        assertEq(token.balanceOf(rando), 0);
    }

    function testBalanceOf_whenQueryingZeroAddress_thenRevert() public {
        givenMintedTokens();

        vm.expectRevert("ERC721: address zero is not a valid owner");

        token.balanceOf(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        ownerOf
    //////////////////////////////////////////////////////////////*/

    function testOwnerOf_whenTokenExists_thenReturnCorrectOwner() public {
        givenMintedTokens();

        assertEq(token.ownerOf(123), owner);
    }

    function testOwnerOf_whenTokenDoesNotExist_thenRevert() public {
        givenMintedTokens();

        vm.expectRevert("ERC721: invalid token ID");

        token.ownerOf(13);
    }

    /*//////////////////////////////////////////////////////////////
                        Transfers via transferFrom
    //////////////////////////////////////////////////////////////*/

    function testTransfer_whenCalledByOwner_shouldTransferTokens() public {
        givenMintedTokens();

        thenTransferWasSuccessful_events(owner, to, 123);

        vm.prank(owner);
        token.transferFrom(owner, to, 123); // TODO should this use _transfer ?

        thenTransferWasSuccessful(owner, to, 123);
    }

    // NOTE this is starting to feel like too much misdirection
    function testTransfer_whenCalledByApprovedEOA_shouldTransferTokens() public {
        givenMintedTokens();
        andSetupApprovals();

        thenTransferWasSuccessful_events(owner, to, 123);

        vm.prank(approved);
        token.transferFrom(owner, to, 123);

        thenTransferWasSuccessful(owner, to, 123);
    }

    function testTransfer_whenCalledByOperator_shouldTransferTokens() public {
        givenMintedTokens();
        andSetupApprovals();

        thenTransferWasSuccessful_events(owner, to, 123);

        vm.prank(operator);
        token.transferFrom(owner, to, 123);

        thenTransferWasSuccessful(owner, to, 123);
    }

    function testTransfer_whenCalledByOwnerWithoutApprovedEOA_shouldTransferTokens() public {
        givenMintedTokens();
        andSetupApprovals();
        vm.prank(owner);
        token.approve(address(0), 123); // revoke approved address

        thenTransferWasSuccessful_events(owner, to, 123);

        vm.prank(owner);
        token.transferFrom(owner, to, 123);

        thenTransferWasSuccessful(owner, to, 123);
    }

    // NOTE unclear on zoom level — should these "whenSentToOwner" be one or multiple tests
    function testTransfer_whenSentToOwner_shouldKeepOwnershipOfToken() public {
        givenMintedTokens();
        andSetupApprovals(); // NOTE also seems silly calling approvals when not part of test conditions

        vm.prank(owner);
        token.transferFrom(owner, owner, 123);

        assertEq(token.ownerOf(123), owner);
    }

    function testTransfer_whenSentToOwner_shouldClearApproval() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.prank(owner);
        token.transferFrom(owner, owner, 123);

        assertEq(token.getApproved(123), address(0));
    }

    function testTransfer_whenSentToOwner_shouldOnlyEmitTransferEvent() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, owner, 123);

        vm.prank(owner);
        token.transferFrom(owner, owner, 123);
    }

    function testTransfer_whenSentToOwner_shouldKeepOwnersBalance() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.prank(owner);
        token.transferFrom(owner, owner, 123);

        assertEq(token.balanceOf(owner), 2);
    }

    // TODO shouldn't this be just for ERC721Enumerable? but found in oz/ERC721.behavior.js#171
    // function testTransfer_whenSentToOwner_shouldKeepSameTokenByIndex() public {
    //     givenMintedTokens();
    //     andSetupApprovals();

    //     vm.prank(owner);
    //     token.transferFrom(owner, to, 123);

    // }

    function testTransfer_whenFromAddressIsNotOwner_shouldRevert() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.expectRevert("ERC721: transfer from incorrect owner");

        vm.prank(owner);
        token.transferFrom(rando, to, 123);
    }

    function testTransfer_whenSenderIsNotAuthorized_shouldRevert() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.expectRevert("ERC721: caller is not token owner nor approved");

        vm.prank(rando);
        token.transferFrom(owner, to, 123);
    }

    function testTransfer_whenTokenDoesNotExist_shouldRevert() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.expectRevert("ERC721: invalid token ID");

        vm.prank(owner);
        token.transferFrom(owner, to, 789);
    }

    function testTransfer_whenToIsZeroAddress_shouldRevert() public {
        givenMintedTokens();
        andSetupApprovals();

        vm.expectRevert("ERC721: transfer to the zero address");

        vm.prank(owner);
        token.transferFrom(owner, address(0), 123);
    }

    // NOTE the below is another approach to porting the OZ hardhat/mocha/chai tests

    // function testTransferFrom_whenTokenIsTransferred_thenUpdateOwner() public {
    //     givenMintedTokens();
    //     andSetupApprovals();

    //     vm.prank(approved);
    //     token.transferFrom(owner, to, 123);

    //     assertEq(token.ownerOf(123), to);
    // }

    // function testTransferFrom_whenTokenIsTransferred_thenEmitTransfer() public {
    //     givenMintedTokens();
    //     andSetupApprovals();

    //     vm.expectEmit(true, true, true, true);
    //     emit Transfer(owner, to, 123);

    //     vm.prank(approved);
    //     token.transferFrom(owner, to, 123);
    // }

    // function testTransferFrom_whenTokenIsTransferred_thenClearApproval() public {
    //     givenMintedTokens();
    //     andSetupApprovals();

    //     vm.prank(approved);
    //     token.transferFrom(owner, to, 123);

    //     assertEq(token.getApproved(123), address(0));
    // }

    // function testTransferFrom_whenTokenIsTransferred_thenEmitApprovalOfZeroAddress() public {
    //     givenMintedTokens();
    //     andSetupApprovals();

    //     vm.expectEmit(true, true, true, true);
    //     emit Approval(owner, address(0), 123);

    //     vm.prank(approved);
    //     token.transferFrom(owner, to, 123);
    // }

    // function testTransferFrom_whenTokenIsTransferred_thenUpdateBalances() public {
    //     givenMintedTokens();
    //     andSetupApprovals();

    //     // to improve test readability
    //     assertEq(token.balanceOf(owner), 2);
    //     assertEq(token.balanceOf(to), 0);

    //     vm.prank(approved);
    //     token.transferFrom(owner, to, 123);

    //     assertEq(token.balanceOf(owner), 1);
    //     assertEq(token.balanceOf(to), 1);
    // }

    // function testTransferFrom_whenTokenIsTransferred_thenUpdateOwners() public {
    //     givenMintedTokens();
    //     andSetupApprovals();

    //     // to improve test readability
    //     assertEq(token.ownerOf(123), owner);

    //     vm.prank(approved);
    //     token.transferFrom(owner, to, 123);

    //     assertEq(token.ownerOf(123), to);
    // }

    /*//////////////////////////////////////////////////////////////
                        Transfers via safeTransferFrom
    //////////////////////////////////////////////////////////////*/

    // TODO

    // function testSafeTransferFrom_shouldTransferToEOA() public {

    // }

    /*//////////////////////////////////////////////////////////////
                        safeMint
    //////////////////////////////////////////////////////////////*/

    // 5 Givens
    // Safe
    // Wrong Data
    // Reverting
    // Panicking
    // Unimplemented Function

    // NOTE purposefully not testing unique parts of OZ's Receiver mock, like logs

    function testSafeMint_whenMintedToSafeReceiverWithData_thenShouldCallOnERC721Recieved() public {
        address receiver = address(new ERC721Recipient());

        token.safeMint(receiver, 123, "0x69");

        assertEq(token.ownerOf(123), receiver);
    }

    function testSafeMint_whenMintedToSafeRecieverWithoutData_thenShouldCallOnERC721Received() public {
        address receiver = address(new ERC721Recipient());

        token.safeMint(receiver, 123);

        assertEq(token.ownerOf(123), receiver);
    }

    function testSafeMint_whenMintedToWrongDataReceiver_thenShouldRevert() public {
        address receiver = address(new WrongReturnDataERC721Recipient());

        vm.expectRevert("ERC721: transfer to non ERC721Receiver implementer");

        token.safeMint(receiver, 123);
    }

    function testSafeMint_whenMintedToRevertingWithMessageReceiver_thenShouldRevert() public {
        address receiver = address(new RevertingWithMessageERC721Recipient());

        vm.expectRevert(IERC721Receiver.onERC721Received.selector);

        token.safeMint(receiver, 123);
    }

    function testSafeMint_whenMintedToRevertingWithoutMessageReceiver_thenShouldRevert() public {
        address receiver = address(new RevertingWithoutMessageERC721Recipient());

        vm.expectRevert("ERC721: transfer to non ERC721Receiver implementer");

        token.safeMint(receiver, 123);
    }

    // NOTE not totally understanding yet what OZ is testing here with 'to a receiver contract that panics'
    function testSafeMint_whenMintedToPanickingReceiver_thenShouldRevert() public {
        address receiver = address(new PanickingERC721Recipient());

        vm.expectRevert(stdError.divisionError);

        token.safeMint(receiver, 123);
    }

    function testSafeMint_whenMintedToNonERC721Receiver_thenShouldRevert() public {
        address receiver = address(new NonERC721Recipient());

        vm.expectRevert("ERC721: transfer to non ERC721Receiver implementer");

        token.safeMint(receiver, 123);
    }

    /*//////////////////////////////////////////////////////////////
                        approve
    //////////////////////////////////////////////////////////////*/

    // 3 Then asserts
    // Then it clears approval
    // Then it approves
    // Then it emits event

    function testApprove_givenNoPriorApproval_whenClearingApproval_thenShouldClearApprovalAndEmitEvent() public {
        givenMintedTokens();

        vm.expectEmit(true, true, true, true);
        emit Approval(owner, address(0), 123);

        vm.prank(owner);
        token.approve(address(0), 123);

        assertEq(token.getApproved(123), address(0));
    }

    function testApprove_givenPriorApproval_whenClearingApproval_thenShouldClearApprovalAndEmitEvent() public {
        givenMintedTokens();
        vm.prank(owner);
        token.approve(approved, 123);

        vm.expectEmit(true, true, true, true);
        emit Approval(owner, address(0), 123);

        vm.prank(owner);
        token.approve(address(0), 123);

        assertEq(token.getApproved(123), address(0));
    }

    function testApprove_givenNoPriorApproval_whenApprovingAddress_thenShouldApproveAndEmitEvent() public {
        givenMintedTokens();

        vm.expectEmit(true, true, true, true);
        emit Approval(owner, approved, 123);

        vm.prank(owner);
        token.approve(approved, 123);

        assertEq(token.getApproved(123), approved);
    }

    function testApprove_givenPriorApprovalOfSameAddress_whenApprovingAddress_thenShouldApproveAndEmitEvent() public {
        givenMintedTokens();
        vm.prank(owner);
        token.approve(approved, 123);

        vm.expectEmit(true, true, true, true);
        emit Approval(owner, approved, 123);

        vm.prank(owner);
        token.approve(approved, 123);

        assertEq(token.getApproved(123), approved);
    }

    function testApprove_givenPriorApprovalOfDifferentAddress_whenApprovingAddress_thenShouldApproveAndEmitEvent()
        public
    {
        givenMintedTokens();
        vm.prank(owner);
        token.approve(rando, 123);

        vm.expectEmit(true, true, true, true);
        emit Approval(owner, approved, 123);

        vm.prank(owner);
        token.approve(approved, 123);

        assertEq(token.getApproved(123), approved);
    }

    function testApprove_whenApprovingOwner_thenShouldRevert() public {
        givenMintedTokens();

        vm.expectRevert("ERC721: approval to current owner");

        vm.prank(owner);
        token.approve(owner, 123);
    }

    // TODO there might be a mistake in OZ ERC721.behavior.js#L512 (expectRevert missing " for all")
    function testApprove_whenSenderIsNotOwner_thenShouldRevert() public {
        givenMintedTokens();

        vm.expectRevert("ERC721: approve caller is not token owner nor approved for all");

        token.approve(approved, 123);
    }

    function testApprove_whenSenderIsAlreadyApproved_thenShouldRevert() public {
        givenMintedTokens();
        vm.prank(owner);
        token.approve(approved, 123);

        // NOTE this is a weird error that OZ throws in this scenario
        vm.expectRevert("ERC721: approve caller is not token owner nor approved for all");

        vm.prank(approved);
        token.approve(rando, 123);
    }

    // TODO implement me
    // function testApprove_whenSenderIsOperator_thenShouldApproveAndEmitEvent() public {

    // }

    function testApprove_whenTokenDoesNotExist_thenShouldRevert() public {
        givenMintedTokens();

        vm.expectRevert("ERC721: invalid token ID");

        token.approve(approved, 789);
    }

    /*//////////////////////////////////////////////////////////////
                        set approval for all
    //////////////////////////////////////////////////////////////*/

    function testSetApprovalForAll_whenSetByOwner_thenShouldApproveTheOperator() public {
        givenMintedTokens();

        vm.prank(owner);
        token.setApprovalForAll(operator, true);

        assertEq(token.isApprovedForAll(owner, operator), true);
    }

    function testSetApprovalForAll_whenSetByOwner_thenShouldEmitApprovalEvent() public {
        givenMintedTokens();

        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(owner, operator, true);

        vm.prank(owner);
        token.setApprovalForAll(operator, true);
    }

    // TODO when the operator was set as not approved

    function testSetApprovalForAll_whenUnsetByOwner_thenShouldRevokeApprovalForAll() public {
        givenMintedTokens();

        vm.startPrank(owner);
        token.setApprovalForAll(operator, true);
        token.setApprovalForAll(operator, false);
        vm.stopPrank();

        assertEq(token.isApprovedForAll(owner, operator), false);
    }

    // TODO when the operator was already approved

    function testSetApprovalForAll_whenOperatorIsOwner_thenShouldRevert() public {
        givenMintedTokens();

        vm.expectRevert("ERC721: approve to caller");

        vm.prank(owner);
        token.setApprovalForAll(owner, true);
    }

    /*//////////////////////////////////////////////////////////////
                        Based on OZ functions, bottoms-up
    //////////////////////////////////////////////////////////////*/

    // supportsInterface

    // balanceOf

    // ownerOf

    // tokenURI

    // approve

    // getApproved

    // setApprovalForAll

    // isApprovedForAll

    // transferFrom

    // safeTransferFrom

    // safeTransferFrom (with data)

    // INTERNAL

    // _safeTransfer

    // _exists

    // _isApprovedOrOwner

    // _safeMint

    // _safeMint (with data)

    // _mint

    // _burn

    // _transfer

    // _approve

    // _setApprovalForAll

    // _requireMinted

    // _checkOnERC721Received

    // _beforeTokenTransfer

    // _afterTokenTransfer
}

contract ERC721Recipient is IERC721Receiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return IERC721Receiver.onERC721Received.selector;
    }
}

contract NonERC721Recipient {}

contract RevertingWithMessageERC721Recipient is IERC721Receiver {
    event log(string info);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public override returns (bytes4) {
        revert(string(abi.encodePacked(IERC721Receiver.onERC721Received.selector)));
    }
}

contract RevertingWithoutMessageERC721Recipient is IERC721Receiver {
    event log(string info);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public override returns (bytes4) {
        revert();
    }
}

contract PanickingERC721Recipient is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public override returns (bytes4) {
        uint256 a = uint256(0) / uint256(0);
        a;
    }
}

contract WrongReturnDataERC721Recipient is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public override returns (bytes4) {
        return 0xDEADCAFE;
    }
}
