// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../src/sm/ERC20Contract.sol";

contract ERC20Test is Test {
    //
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    ERC20Contract token;

    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function setUp() public {
        token = new ERC20Contract("Token", "TKN", 18);
    }

    function testInvariantMetadata() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
        assertEq(token.decimals(), 18);
    }

    ////////////////////////////////////////////////
    ////////////////    Mint    ////////////////////
    ////////////////////////////////////////////////

    function testMint() public {
        token.mint(address(0xBABE), 1e18);

        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(address(0xBABE)), 1e18);
    }

    ////////////////////////////////////////////////
    ////////////////    Burn    ////////////////////
    ////////////////////////////////////////////////

    function testBurn() public {
        token.mint(address(0xBABE), 1e18);
        token.burn(address(0xBABE), 0.9e18);

        assertEq(token.totalSupply(), 0.1e18);
        assertEq(token.balanceOf(address(0xBABE)), 0.1e18);
    }

    ////////////////////////////////////////////////
    ////////////////    Approve    /////////////////
    ////////////////////////////////////////////////

    function testApprove() public {
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), address(0xBABE), 1e18);

        assertTrue(token.approve(address(0xBABE), 1e18));
        assertEq(token.allowance(address(this), address(0xBABE)), 1e18);
    }

    ////////////////////////////////////////////////
    ////////////////    Transfer    ////////////////
    ////////////////////////////////////////////////

    function testTransfer() public {
        token.mint(address(this), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0xBABE), 1e18);

        assertTrue(token.transfer(address(0xBABE), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(0xBABE)), 1e18);
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, address(0xBABE), 1e18);

        assertTrue(token.transferFrom(from, address(0xBABE), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.allowance(from, address(this)), 0);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBABE)), 1e18);
    }

    function testTransferWhenInsufficientBalanceShouldFail() public {
        token.mint(address(this), 0.9e18);

        vm.expectRevert(stdError.arithmeticError);

        token.transfer(address(0xBABE), 1e18);
    }

    function testTransferFromWhenInsufficientAllowanceShouldFail() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 0.9e18);

        vm.expectRevert(stdError.arithmeticError);

        token.transferFrom(from, address(0xBABE), 1e18);
    }

    function testTransferFromInsufficientBalanceShouldFail() public {
        address from = address(0xABCD);

        token.mint(from, 0.9e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        vm.expectRevert(stdError.arithmeticError);

        token.transferFrom(from, address(0xBABE), 1e18);
    }

    function testAllowanceWhenPartiallySpent() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        token.transferFrom(from, address(0xBABE), 0.9e18);

        assertEq(token.allowance(from, address(this)), 0.1e18);
    }

    function testInfiniteApproveTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), type(uint256).max);

        assertTrue(token.transferFrom(from, address(0xBABE), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.allowance(from, address(this)), type(uint256).max);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBABE)), 1e18);
    }

    ////////////////////////////////////////////////
    ////////////////    Permit    //////////////////
    ////////////////////////////////////////////////

    // https://eips.ethereum.org/EIPS/eip-2612

    function testPermit() public {
        uint256 privateKey = 0xBABE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xABCD), 1e18, 0, block.timestamp))
                )
            )
        );

        token.permit(owner, address(0xABCD), 1e18, block.timestamp, v, r, s);

        assertEq(token.allowance(owner, address(0xABCD)), 1e18);
        assertEq(token.nonces(owner), 1);
    }

    function testPermitWhenBadNonceShouldFail() public {
        uint256 privateKey = 0xBABE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xABCD), 1e18, 1, block.timestamp))
                )
            )
        );

        vm.expectRevert("INVALID_SIGNER");

        token.permit(owner, address(0xABCD), 1e18, block.timestamp, v, r, s);
    }

    function testPermitWhenBadDeadlineShouldFail() public {
        uint256 privateKey = 0xBABE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xABCD), 1e18, 0, block.timestamp))
                )
            )
        );

        vm.expectRevert("INVALID_SIGNER");

        token.permit(owner, address(0xABCD), 1e18, block.timestamp + 1, v, r, s);
    }

    function testPermitWhenPastDeadlineShouldFail() public {
        uint256 privateKey = 0xBABE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xABCD), 1e18, 0, block.timestamp - 1))
                )
            )
        );

        vm.expectRevert("PERMIT_DEADLINE_EXPIRED");

        token.permit(owner, address(0xABCD), 1e18, block.timestamp - 1, v, r, s);
    }

    function testDoublePermitShouldFail() public {
        uint256 privateKey = 0xBABE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xABCD), 1e18, 0, block.timestamp))
                )
            )
        );

        token.permit(owner, address(0xABCD), 1e18, block.timestamp, v, r, s);

        vm.expectRevert("INVALID_SIGNER");

        token.permit(owner, address(0xABCD), 1e18, block.timestamp, v, r, s);
    }

    // TODO add fuzz tests

    // TODO add invariant test
}
