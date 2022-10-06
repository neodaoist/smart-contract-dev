// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin/contracts/security/Pausable.sol";

contract OwnableAndPausableContract is Ownable, Pausable {
    //
    constructor() {
        _transferOwnership(address(0xBABE));
    }

    function affordSomethingToEndUsers() public whenNotPaused returns (bool) {
        return true;
    }

    function handleOwnerBusiness() public onlyOwner returns (bool) {
        return true;
    }

    function beginEmergency() public onlyOwner whenNotPaused {
        _pause();
    }

    function handleEmergencyBusiness() public onlyOwner whenPaused {
        //
    }

    function resolveEmergency() public onlyOwner whenPaused {
        _unpause();
    }
}

// maybe kinda more integration/acceptance/e2e level testing ?
// or, maybe just a simpler and clearer style of 'unit of behavior' testing
contract OwnableAndPausableTest is Test {
    //
    OwnableAndPausableContract op;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        op = new OwnableAndPausableContract();
    }

    function testInitialConditionsAfterDeploy() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(0), address(this));
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), address(0xBABE));

        // using a local contract in order to assert that the above events get logged during construction
        OwnableAndPausableContract initial = new OwnableAndPausableContract();

        assertEq(initial.owner(), address(0xBABE));
        assertFalse(initial.paused());

        vm.prank(address(0xBABE));
        assertTrue(initial.handleOwnerBusiness());

        vm.prank(address(0xABCD));
        assertTrue(initial.affordSomethingToEndUsers());
    }

    function testOwnableAccess() public {
        vm.expectRevert("Ownable: caller is not the owner");
        op.handleOwnerBusiness();

        vm.expectRevert("Ownable: caller is not the owner");
        op.beginEmergency();

        vm.prank(address(0xBABE));
        op.beginEmergency();

        vm.expectRevert("Ownable: caller is not the owner");
        op.handleEmergencyBusiness();

        vm.expectRevert("Ownable: caller is not the owner");
        op.resolveEmergency();
    }

    function testPausableSecurity() public {
        vm.expectRevert("Pausable: not paused");
        vm.prank(address(0xBABE));
        op.handleEmergencyBusiness();

        vm.expectRevert("Pausable: not paused");
        vm.prank(address(0xBABE));
        op.resolveEmergency();

        vm.prank(address(0xBABE));
        op.beginEmergency();

        vm.expectRevert("Pausable: paused");
        op.affordSomethingToEndUsers();

        vm.expectRevert("Pausable: paused");
        vm.prank(address(0xBABE));
        op.beginEmergency();
    }

    function testHandleOwnerBusinessAnyTime() public {
        vm.startPrank(address(0xBABE));

        // when not paused
        assertTrue(op.handleOwnerBusiness());

        op.beginEmergency();

        // when paused
        assertTrue(op.handleOwnerBusiness());
    }

    function testBeginEmergencySituation() public {
        assertFalse(op.paused());

        vm.expectEmit(true, true, true, true);
        emit Paused(address(0xBABE));

        vm.prank(address(0xBABE));
        op.beginEmergency();

        assertTrue(op.paused());

        vm.expectRevert("Pausable: paused");
        op.affordSomethingToEndUsers();

        vm.prank(address(0xBABE));
        op.handleEmergencyBusiness();
    }

    function testResolveEmergencySituation() public {
        vm.prank(address(0xBABE));
        op.beginEmergency();

        assertTrue(op.paused());

        vm.expectEmit(true, true, true, true);
        emit Unpaused(address(0xBABE));

        vm.prank(address(0xBABE));
        op.resolveEmergency();

        assertFalse(op.paused());

        assertTrue(op.affordSomethingToEndUsers());
    }
}
