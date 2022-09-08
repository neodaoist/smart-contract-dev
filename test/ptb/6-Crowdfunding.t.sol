// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// inspired by https://programtheblockchain.com/posts/2018/01/19/writing-a-crowdfunding-contract-a-la-kickstarter/
contract CrowdfundingTest is Test {
    //
    Crowdfunding cf;

    // People 
    address OWNER = address(0xBABE);
    address RANDOM = address(0xABCD);
    address PLEDGER1 = address(0x1);
    address PLEDGER2 = address(0x2);
    address PLEDGER3 = address(0x3);
    address PLEDGER4 = address(0x4);
    address PLEDGER5 = address(0x5);

    // Time
    uint256 START = 2_000_000_000; // unix timestamp of ~2033-05-18
    uint256 DAYS = 3;

    // Money
    uint256 GOAL = 5 ether;

    function setUp() public {
        vm.warp(START);

        deal(PLEDGER1, 10 ether);
        deal(PLEDGER2, 10 ether);
        deal(PLEDGER3, 10 ether);
        deal(PLEDGER4, 10 ether);
        deal(PLEDGER5, 10 ether);

        vm.prank(OWNER);
        cf = new Crowdfunding(DAYS, GOAL);
    }

    function test_initial() public {
        assertEq(cf.owner(), OWNER);
        assertEq(cf.deadline(), START + (DAYS * 1 days));
        assertEq(cf.goal(), GOAL);
    }

    /*//////////////////////////////////////////////////////////////
                        Pledging Funds
    //////////////////////////////////////////////////////////////*/

    function test_pledge() public {
        vm.prank(PLEDGER1);
        cf.pledge{value: 1 ether}(1 ether);
        vm.prank(PLEDGER2);
        cf.pledge{value: 0.1 ether}(0.1 ether);
        vm.prank(PLEDGER3);
        cf.pledge{value: 1.9 ether}(1.9 ether);
        vm.prank(PLEDGER4);
        cf.pledge{value: 1 ether}(1 ether);
        vm.prank(PLEDGER5);
        cf.pledge{value: 1 ether}(1 ether);

        assertEq(address(cf).balance, 5 ether);
        assertEq(cf.pledgeOf(PLEDGER1), 1 ether);
        assertEq(cf.pledgeOf(PLEDGER2), 0.1 ether);
        assertEq(cf.pledgeOf(PLEDGER3), 1.9 ether);
        assertEq(cf.pledgeOf(PLEDGER4), 1 ether);
        assertEq(cf.pledgeOf(PLEDGER5), 1 ether);
    }

    function test_pledge_whenAfterDeadline_shouldRevert() public {
        vm.expectRevert("Crowdfunding: cannot pledge after deadline");

        vm.warp(START + (DAYS * 1 days) + 1 days); // after deadline

        vm.prank(PLEDGER1);
        cf.pledge{value: 1 ether}(1 ether);
    }

    function test_pledge_whenInvalidPledgeAmount_shouldRevert() public {
        vm.expectRevert("Crowdfunding: invalid pledge amount");

        vm.prank(PLEDGER1);
        cf.pledge{value: 0.9 ether}(1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        Withdrawing Funds
    //////////////////////////////////////////////////////////////*/

    function test_claimFunds() public {
        vm.prank(PLEDGER1);
        cf.pledge{value: GOAL}(GOAL);

        vm.warp(START + (DAYS * 1 days));

        vm.prank(OWNER);
        cf.claimFunds();

        assertEq(address(cf).balance, 0 ether);
        assertEq(OWNER.balance, GOAL);
    }

    function test_claimFunds_whenNotOwner_shouldRevert() public {
        vm.prank(PLEDGER1);
        cf.pledge{value: GOAL}(GOAL);

        vm.warp(START + (DAYS * 1 days));

        vm.expectRevert("Crowdfunding: only owner can claim funds");

        vm.prank(RANDOM);
        cf.claimFunds();
    }

    function test_claimFunds_whenBeforeDeadline_shouldRevert() public {
        vm.prank(PLEDGER1);
        cf.pledge{value: GOAL}(GOAL);

        vm.warp(START + (DAYS * 1 days) - 1 days); // before deadline
        
        vm.expectRevert("Crowdfunding: cannot claim funds before deadline");

        vm.prank(OWNER);
        cf.claimFunds();
    }

    function test_claimFunds_whenGoalNotReached_shouldRevert() public {
        vm.prank(PLEDGER1);
        cf.pledge{value: GOAL - 0.1 ether}(GOAL - 0.1 ether); // goal not reached

        vm.warp(START + (DAYS * 1 days));
        
        vm.expectRevert("Crowdfunding: cannot claim funds because goal was not reached");

        vm.prank(OWNER);
        cf.claimFunds();
    }

    function test_getRefund() public {
        vm.prank(PLEDGER1);
        cf.pledge{value: 1 ether}(1 ether);
        vm.prank(PLEDGER2);
        cf.pledge{value: 1 ether}(1 ether);
        vm.prank(PLEDGER3);
        cf.pledge{value: 1 ether}(1 ether);
        vm.prank(PLEDGER4);
        cf.pledge{value: 1 ether}(1 ether);

        // precondition checks
        assertEq(PLEDGER1.balance, 9 ether);
        assertEq(PLEDGER2.balance, 9 ether);
        assertEq(PLEDGER3.balance, 9 ether);
        assertEq(PLEDGER4.balance, 9 ether);
        assertEq(address(cf).balance, 4 ether);

        vm.warp(START + (DAYS * 1 days));
        
        vm.prank(PLEDGER1);
        cf.getRefund();
        assertEq(PLEDGER1.balance, 10 ether);
        assertEq(address(cf).balance, 3 ether);

        vm.prank(PLEDGER2);
        cf.getRefund();
        assertEq(PLEDGER1.balance, 10 ether);
        assertEq(address(cf).balance, 2 ether);

        vm.prank(PLEDGER3);
        cf.getRefund();
        assertEq(PLEDGER1.balance, 10 ether);
        assertEq(address(cf).balance, 1 ether);

        vm.prank(PLEDGER4);
        cf.getRefund();
        assertEq(PLEDGER1.balance, 10 ether);
        assertEq(address(cf).balance, 0 ether);
    }

    function test_getRefund_whenBeforeDeadline_shouldRevert() public {
        vm.startPrank(PLEDGER1);
        cf.pledge{value: GOAL}(GOAL);
        
        vm.warp(START + (DAYS * 1 days) - 1 days); // before deadline

        vm.expectRevert("Crowdfunding: cannot get refund before deadline");

        cf.getRefund();        
    }

    function test_getRefund_whenGoalReached_shouldRevert() public {
        vm.startPrank(PLEDGER1);
        cf.pledge{value: GOAL}(GOAL); // goal successfully reached
        
        vm.warp(START + (DAYS * 1 days));

        vm.expectRevert("Crowdfunding: cannot get refund because goal was reached");

        cf.getRefund();
    }

    function test_getRefund_whenNoPledge_shouldRevert() public {
        vm.warp(START + (DAYS * 1 days));

        vm.expectRevert("Crowdfunding: no pledge to refund");

        vm.prank(PLEDGER1);
        cf.getRefund();
    }

    function test_getRefund_whenAlreadyGotRefund_shouldRevert() public {
        vm.startPrank(PLEDGER1);
        cf.pledge{value: 1 ether}(1 ether);
        
        vm.warp(START + (DAYS * 1 days));

        cf.getRefund();

        vm.expectRevert("Crowdfunding: no pledge to refund");

        cf.getRefund();
    }
}

contract Crowdfunding {
    //
    address public owner;
    uint256 public deadline;
    uint256 public goal;

    mapping(address => uint256) public pledgeOf;

    constructor (uint256 _numberOfDays, uint256 _fundingGoal) {
        owner = msg.sender;
        deadline = block.timestamp + (_numberOfDays * 1 days);
        goal = _fundingGoal;
    }

    /*//////////////////////////////////////////////////////////////
                        Pledging Funds
    //////////////////////////////////////////////////////////////*/

    function pledge(uint256 _pledgeAmount) public payable {
        require(block.timestamp < deadline, "Crowdfunding: cannot pledge after deadline");
        require(msg.value == _pledgeAmount, "Crowdfunding: invalid pledge amount");

        pledgeOf[msg.sender] += _pledgeAmount;
    }

    /*//////////////////////////////////////////////////////////////
                        Withdrawing Funds
    //////////////////////////////////////////////////////////////*/

    function claimFunds() public {
        require(msg.sender == owner, "Crowdfunding: only owner can claim funds");
        require(block.timestamp >= deadline, "Crowdfunding: cannot claim funds before deadline");
        require(address(this).balance >= goal, "Crowdfunding: cannot claim funds because goal was not reached");

        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        require(success, "Crowdfunding: claim funds failed");
    }

    function getRefund() public {
        require(block.timestamp >= deadline, "Crowdfunding: cannot get refund before deadline");
        require(address(this).balance < goal, "Crowdfunding: cannot get refund because goal was reached");
        require(pledgeOf[msg.sender] > 0 ether, "Crowdfunding: no pledge to refund");

        uint256 refundAmount = pledgeOf[msg.sender];
        pledgeOf[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: refundAmount}("");

        require(success, "Crowdfunding: get refund failed");
    }
}
