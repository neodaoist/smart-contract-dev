// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import "forge-std/Test.sol";

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";

// event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
// modifier onlyOwner
// function owner() view
// function renounceOwnership()
// function transferOwnership(address newOwner)

contract OwnableContract is Ownable {
    //
    function handleOwnerBusiness() public onlyOwner {
        //
    }
}

contract OwnableTest is Test {
    //
    OwnableContract ownable;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        ownable = new OwnableContract();
    }

    function testOwnershipTransferredDuringConstruction() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(0), address(this));

        new OwnableContract();
    }

    function testOwner() public {
        assertEq(ownable.owner(), address(this));
    }

    function testOnlyOwnerFunction() public {
        // no revert
        ownable.handleOwnerBusiness();
    }

    function testOnlyOwnerFunctionCanNotBeCalledByNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(0xBABE));
        ownable.handleOwnerBusiness();
    }

    function testRenounceOwnership() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), address(0));

        ownable.renounceOwnership();

        assertEq(ownable.owner(), address(0));

        // not sure if this assert is valuable or duplicative
        vm.expectRevert("Ownable: caller is not the owner");
        ownable.handleOwnerBusiness();
    }

    function testTransferOwnership() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), address(0xBABE));

        ownable.transferOwnership(address(0xBABE));

        assertEq(ownable.owner(), address(0xBABE));

        // no revert
        vm.prank(address(0xBABE));
        ownable.handleOwnerBusiness();

        // not sure if this assert is valuable or duplicative
        vm.expectRevert("Ownable: caller is not the owner");
        ownable.handleOwnerBusiness();
    }

    function testCantTransferOwnershipToZeroAddress() public {
        vm.expectRevert("Ownable: new owner is the zero address");
        ownable.transferOwnership(address(0));
    }
}
