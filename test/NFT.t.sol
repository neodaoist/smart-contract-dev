// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "ds-test/test.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/NFT.sol";

contract NFTTest is DSTest {
  using stdStorage for StdStorage;

  Vm private vm = Vm(HEVM_ADDRESS);
  NFT private nft;
  StdStorage private stdstore;

  function setUp() public {
    // Deploy NFT contract
    nft = new NFT("Lyfe NFT", "LYFE", "baseUri");
  }

  function testFailNoMintPricePaid() public {
    nft.mintTo(address(1));
  }

  function testMintPricePaid() public {
    nft.mintTo{value: 0.08 ether}(address(1));
  }
}

contract Receiver is ERC721TokenReceiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 id,
    bytes calldata data
  ) override external returns (bytes4) {
    return this.onERC721Received.selector;
  }
}
