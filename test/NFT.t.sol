// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NFT.sol";

contract NFTTest is Test {
    //
    using stdStorage for StdStorage;

    NFT private nft;

    function setUp() public {
        nft = new NFT("Lyfe NFT", "LYFE", "baseUri");
    }

    function testFailNoMintPricePaid() public {
        nft.mintTo(address(1));
    }

    function testMintPricePaid() public {
        nft.mintTo{value: 0.08 ether}(address(1));
    }

    function testFailMaxSupplyReached() public {
        uint256 slot = stdstore.target(address(nft)).sig("currentTokenId()").find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(10000));
        vm.store(address(nft), loc, mockedCurrentTokenId);

        nft.mintTo{value: 0.08 ether}(address(1));
    }

    // new new
    function testOneLessThanMaxSupply() public {
        uint256 slot = stdstore.target(address(nft)).sig("currentTokenId()").find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(9999));
        vm.store(address(nft), loc, mockedCurrentTokenId);

        nft.mintTo{value: 0.08 ether}(address(1));
    }

    function testFailMintToZeroAddress() public {
        nft.mintTo{value: 0.08 ether}(address(0));
    }

    function testNewMintOwnerRegistered() public {
        nft.mintTo{value: 0.08 ether}(address(1));
        uint256 slotOfNewOwner = stdstore.target(address(nft)).sig(nft.ownerOf.selector).with_key(1).find();

        uint160 ownerOfTokenIdOne = uint160(uint256((vm.load(address(nft), bytes32(abi.encode(slotOfNewOwner))))));
        assertEq(address(ownerOfTokenIdOne), address(1));
    }

    // alternate approach — why not check if the new owner was registered with ownerOf() ?
    function testAlt_NewMintOwnerRegistered() public {
        nft.mintTo{value: 0.08 ether}(address(1));
        assertEq(nft.ownerOf(nft.currentTokenId()), address(1));
    }

    function testBalanceIncremented() public {
        nft.mintTo{value: 0.08 ether}(address(1));
        uint256 slotBalance = stdstore.target(address(nft)).sig(nft.balanceOf.selector).with_key(address(1)).find();

        uint256 balanceFirstMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        nft.mintTo{value: 0.08 ether}(address(1));
        uint256 balanceSecondMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    // alternate approach — why not check if the balance incremented with balanceOf() ?
    function testAlt_BalanceIncremented() public {
        nft.mintTo{value: 0.08 ether}(address(1));
        assertEq(nft.balanceOf(address(1)), 1);

        nft.mintTo{value: 0.08 ether}(address(1));
        assertEq(nft.balanceOf(address(1)), 2);
    }

    function testSafeContractReceived() public {
        Receiver receiver = new Receiver();
        nft.mintTo{value: 0.08 ether}(address(receiver));
        uint256 slotBalance =
            stdstore.target(address(nft)).sig(nft.balanceOf.selector).with_key(address(receiver)).find();

        uint256 balance = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balance, 1);
    }

    // alternate approach — why not check if the safe contract received with balanceOf() ?
    function testAlt_SafeContractReceived() public {
        nft.mintTo{value: 0.08 ether}(address(1));
        assertEq(nft.balanceOf(address(1)), 1);
    }

    function testFailUnsafeContractReceiver() public {
        vm.etch(address(1), bytes("mock code"));
        nft.mintTo{value: 0.08 ether}(address(1));
    }

    function testWithdrawalWorksAsOwner() public {
        // Mint an NFT, sending ETH to the contract
        Receiver receiver = new Receiver();
        address payable payee = payable(address(0x1337));
        uint256 priorPayeeBalance = payee.balance;
        nft.mintTo{value: nft.MINT_PRICE()}(address(receiver));

        // Check that the balance of the contract is correct
        assertEq(address(nft).balance, nft.MINT_PRICE());

        // Withdraw the balanace and check it was transferred
        uint256 nftContractBalance = address(nft).balance;
        nft.withdrawPayments(payee);
        assertEq(payee.balance, priorPayeeBalance + nftContractBalance);
    }

    // alternate approach — why did we need to use a Receiver there ?
    function testAlt_WithdrawalWorksAsOwner() public {
        // Mint an NFT, sending ETH to the contract
        address payable payee = payable(address(0x1337));
        uint256 priorPayeeBalance = payee.balance;
        nft.mintTo{value: nft.MINT_PRICE()}(address(1));

        // Check that the balance of the contract is correct
        assertEq(address(nft).balance, nft.MINT_PRICE());

        // Withdraw the balanace and check it was transferred
        uint256 nftContractBalance = address(nft).balance;
        nft.withdrawPayments(payee);
        assertEq(payee.balance, priorPayeeBalance + nftContractBalance);
    }

    function testWithdrawalFailsAsNoOwner() public {
        // Mint an NFT, sending ETH to the contract
        Receiver receiver = new Receiver();
        nft.mintTo{value: nft.MINT_PRICE()}(address(receiver));

        // Check that the balance of the contract is correct
        assertEq(address(nft).balance, nft.MINT_PRICE());

        // Check that a non-owner cannot withdraw
        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(address(0xd3ad)); // could also just use vm.prank(), but we use start+stop to be explicit ?
        nft.withdrawPayments(payable(address(0xd3ad)));
        vm.stopPrank();
    }
}

contract Receiver is ERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint256 id, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}
