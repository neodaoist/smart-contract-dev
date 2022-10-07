// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// inspired by https://programtheblockchain.com/posts/2018/03/16/flipping-a-coin-in-ethereum/
contract CoinFlipTest is Test {
    //
    CoinFlip flip;

    address p1 = address(0xA1);
    address p2 = address(0xA2);
    address rando = address(0xABCD);

    bytes32 nonce = bytes32("Setec Astronomy");

    function setUp() public {
        vm.deal(p1, 10 ether);
        vm.deal(p2, 10 ether);
        vm.deal(rando, 10 ether);

        // 0x925152320d5153c943753783ff437a645a9836cf542b5f739e6083bf6dff320b
        bytes32 commitment = keccak256(abi.encodePacked(true, nonce));
        vm.prank(p1);
        flip = new CoinFlip{value: 1 ether}(commitment);
    }

    function test_initialState() public {
        assertEq(flip.player1(), p1);
        assertEq(flip.player1Commitment(), keccak256(abi.encodePacked(true, nonce)));
        assertEq(flip.betAmount(), 1 ether);
    }

    function test_cancel() public {
        // precondition checks
        assertEq(address(flip).balance, 1 ether);
        assertEq(p1.balance, 9 ether);

        vm.prank(p1);
        flip.cancel();

        assertEq(flip.betAmount(), 0);
        assertEq(address(flip).balance, 0 ether);
        assertEq(p1.balance, 10 ether);
    }

    function test_cancel_whenNotPlayer1_shouldRevert() public {
        vm.expectRevert("CoinFlip: only player1 can cancel bet");

        vm.prank(rando);
        flip.cancel();
    }

    function test_cancel_whenBetAlreadyTaken_shouldRevert() public {
        vm.prank(p2);
        flip.takeBet{value: 1 ether}(true);

        vm.expectRevert("CoinFlip: cannot cancel after bet was taken");

        vm.prank(p1);
        flip.cancel();
    }

    function test_takeBet() public {
        vm.prank(p2);
        flip.takeBet{value: 1 ether}(true);

        assertEq(flip.player2(), p2);
        assertEq(flip.player2Choice(), true);
        assertEq(flip.expiration(), block.timestamp + 24 hours);
    }

    function test_takeBet_whenBetAlreadyTaken_shouldRevert() public {
        vm.prank(p2);
        flip.takeBet{value: 1 ether}(true);

        vm.expectRevert("CoinFlip: cannot take bet after it was already taken");

        vm.prank(rando);
        flip.takeBet{value: 1 ether}(true);
    }

    function test_takeBet_whenBetAmountIncorrect_shouldRevert() public {
        vm.expectRevert("CoinFlip: incorrect bet amount");

        vm.prank(p2);
        flip.takeBet{value: 0.9 ether}(true);

        vm.expectRevert("CoinFlip: incorrect bet amount");

        vm.prank(p2);
        flip.takeBet{value: 1.1 ether}(true);
    }

    function test_reveal_whenWinningChoice() public {
        vm.prank(p2);
        flip.takeBet{value: 1 ether}(true);

        vm.prank(p1);
        flip.reveal(true, nonce);

        assertEq(p1.balance, 9 ether);
        assertEq(p2.balance, 11 ether);
        assertEq(address(flip).balance, 0 ether);
    }

    function test_reveal_whenLosingChoice() public {
        vm.prank(p2);
        flip.takeBet{value: 1 ether}(false);

        vm.prank(p1);
        flip.reveal(true, nonce);

        assertEq(p1.balance, 11 ether);
        assertEq(p2.balance, 9 ether);
        assertEq(address(flip).balance, 0 ether);
    }

    // note technically player1 does not need to perform the reveal() tx and
    // the PTB example mentions this. I didn't include access control, but I
    // do still prank from player1 in tests bc that is most realistic. I would 
    // probably limit access to player1 in a real world application, bc unless
    // something outside the trust model is happening, no one else should know
    // player1's choice or nonce – i.e., principle of least common mechanism,
    // economy of mechanism, and similar concepts.
    function test_reveal_whenInvalidChoiceOrNonceOrBoth_shouldRevert() public {
        vm.prank(p2);
        flip.takeBet{value: 1 ether}(true);

        vm.expectRevert("CoinFlip: does not match commitment");

        vm.prank(p1);
        flip.reveal(false, nonce); // bad choice

        vm.expectRevert("CoinFlip: does not match commitment");

        vm.prank(p1);
        flip.reveal(true, bytes32("other")); // bad nonce

        vm.expectRevert("CoinFlip: does not match commitment");

        vm.prank(p1);
        flip.reveal(false, bytes32("other")); // bad choice and nonce
    }

    function test_reveal_whenBetNotTakenYet_shouldRevert() public {
        vm.expectRevert("CoinFlip: cannot reveal before bet is taken");

        vm.prank(p1);
        flip.reveal(true, nonce);
    }

    function test_reveal_whenAfterExpiration_shouldRevert() public {
        vm.prank(p2);
        flip.takeBet{value: 1 ether}(true);

        vm.expectRevert("CoinFlip: cannot reveal after bet expiration");

        vm.warp(block.timestamp + 24 hours);
        vm.prank(p1);
        flip.reveal(true, nonce);
    }

    function test_claimTimeout() public {
        vm.prank(p2);
        flip.takeBet{value: 1 ether}(true);

        vm.warp(block.timestamp + 24 hours);

        // note again, does not enforce access control, but most realistic that player2 performs — 
        // could/would/should add tests around "anyone can peform", Or enforce access control
        vm.prank(p2);
        flip.claimTimeout();

        assertEq(p1.balance, 9 ether);
        assertEq(p2.balance, 11 ether);
        assertEq(address(flip).balance, 0 ether);
    }

    function test_claimTimeout_whenBeforeExpiration_shouldRevert() public {
        vm.prank(p2);
        flip.takeBet{value: 1 ether}(true);

        vm.warp(block.timestamp + 24 hours - 1 seconds);

        vm.expectRevert("CoinFlip: cannot claim timeout before bet expiration");

        vm.prank(p2);
        flip.claimTimeout();
    }
}

contract CoinFlip {
    //
    address public player1;
    bytes32 public player1Commitment;

    uint256 public betAmount;

    address public player2;
    bool public player2Choice;

    uint256 public expiration = 2 ** 256 - 1; // effectively open forever, until taken or cancelled

    constructor(bytes32 commitment) payable {
        player1 = msg.sender;
        player1Commitment = commitment;
        betAmount = msg.value;
    }

    function cancel() public {
        require(msg.sender == player1, "CoinFlip: only player1 can cancel bet");
        require(player2 == address(0), "CoinFlip: cannot cancel after bet was taken");

        betAmount = 0;
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function takeBet(bool choice) public payable {
        require(player2 == address(0), "CoinFlip: cannot take bet after it was already taken");
        require(msg.value == betAmount, "CoinFlip: incorrect bet amount");

        player2 = msg.sender;
        player2Choice = choice;

        expiration = block.timestamp + 24 hours;
    }

    function reveal(bool choice, bytes32 nonce) public {
        require(player2 != address(0), "CoinFlip: cannot reveal before bet is taken");
        require(block.timestamp < expiration, "CoinFlip: cannot reveal after bet expiration");

        require(keccak256(abi.encodePacked(choice, nonce)) == player1Commitment, "CoinFlip: does not match commitment");

        if (player2Choice == choice) {
            (bool success, ) = payable(player2).call{value: address(this).balance}("");
            require(success);
        } else {
            (bool success, ) = payable(player1).call{value: address(this).balance}("");
            require(success);
        }
    }

    function claimTimeout() public {
        require(block.timestamp >= expiration, "CoinFlip: cannot claim timeout before bet expiration");

        (bool success, ) = payable(player2).call{value: address(this).balance}("");
        require(success);
    }
}
