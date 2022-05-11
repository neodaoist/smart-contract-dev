// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "forge-std/Test.sol";
import "../src/ERC721Contract.sol";

contract ERC721Test is Test {
    using stdStorage for StdStorage;

    ERC721Contract token;

    function setUp() public {
      token = new ERC721Contract("Token", "TKN");
    }

    ////////////////////////////////////////////////
    ////////////////    Mint    ////////////////////
    ////////////////////////////////////////////////

    function testMint() public {
      token.mint(address(0xBABE), 1337);

      assertEq(token.balanceOf(address(0xBABE)), 1);
      assertEq(token.ownerOf(1337), address(0xBABE));
    }

    //

    ////////////////////////////////////////////////
    ////////////////    Safe Mint    ///////////////
    ////////////////////////////////////////////////

    //

    ////////////////////////////////////////////////
    ////////////////    Burn    ////////////////////
    ////////////////////////////////////////////////

    function testBurn() public {
      token.mint(address(0xBABE), 1337);
      token.burn(1337);

      assertEq(token.balanceOf(address(0xBABE)), 0);

      vm.expectRevert("NOT_MINTED");
      token.ownerOf(1337);
    }

    //

    ////////////////////////////////////////////////
    ////////////////    Approve    /////////////////
    ////////////////////////////////////////////////

    function testApprove() public {
      token.mint(address(this), 1337);

      token.approve(address(0xBABE), 1337);

      assertEq(token.getApproved(1337), address(0xBABE));
    }

    function testApproveBurn() public {
      token.mint(address(this), 1337);

      token.approve(address(0xBABE), 1337);

      token.burn(1337);

      assertEq(token.balanceOf(address(this)), 0);
      assertEq(token.getApproved(1337), address(0));

      vm.expectRevert("NOT_MINTED");
      token.ownerOf(1337);
    }

    function testApproveAll() public {
      token.setApprovalForAll(address(0xBABE), true);

      assertTrue(token.isApprovedForAll(address(this), address(0xBABE)));
    }

    ////////////////////////////////////////////////
    ////////////////    Transfer    ////////////////
    ////////////////////////////////////////////////

    // 

    ////////////////////////////////////////////////
    ////////////////    Safe Transfer    ///////////
    ////////////////////////////////////////////////

    //

    ////////////////////////////////////////////////
    ////////////////    Metadata    ////////////////
    ////////////////////////////////////////////////

    function testInvariantMetadata() public {
      assertEq(token.name(), "Token");
      assertEq(token.symbol(), "TKN");
    }

    //
    
  }

  contract ERC721Recipient is ERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(
      address _operator,
      address _from,
      uint256 _id,
      bytes calldata _data
    ) public virtual override returns (bytes4) {
      operator = _operator;
      from = _from;
      id = _id;
      data = _data;

      return ERC721TokenReceiver.onERC721Received.selector;
    }
}
