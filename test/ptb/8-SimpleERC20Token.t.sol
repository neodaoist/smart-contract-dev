// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// inspired by https://programtheblockchain.com/posts/2018/01/30/writing-an-erc20-token-contract/
contract SimpleERC20TokenTest is Test {
    //
    SimpleERC20Token token;

    address deployer = address(0xCAFE);

    function setUp() public {
        vm.deal(deployer, 10 ether);
        vm.prank(deployer);
        token = new SimpleERC20Token();
    }

    function test_initial() public {
        vm.expectEmit(true, true, true, true);
        emit Events.Transfer(address(0), deployer, 1_000_000 * 10 ** 18);

        vm.prank(deployer);
        SimpleERC20Token local = new SimpleERC20Token();

        assertEq(local.balanceOf(deployer), local.totalSupply());
    }

    function test_nameSymbolDecimals() public {
        assertEq(token.name(), "Simple ERC20 Token");
        assertEq(token.symbol(), "SET");
        assertEq(token.decimals(), 18);
    }

    function test_totalSupply() public {
        assertEq(token.totalSupply(), 1_000_000 * 10 ** token.decimals());
    }

    function test_balanceOf() public {
        assertEq(token.balanceOf(deployer), token.totalSupply());
        assertEq(token.balanceOf(address(0xABCD)), 0);
    }

    function test_transfer() public {
        vm.expectEmit(true, true, true, true);
        emit Events.Transfer(deployer, address(0xABCD), 100e18);

        vm.prank(deployer);
        bool success = token.transfer(address(0xABCD), 100e18);

        assertTrue(success);
        assertEq(token.balanceOf(address(0xABCD)), 100e18);
        assertEq(token.balanceOf(deployer), 999_900e18);
    }

    function test_transfer_whenSubsequentTransfers() public {
        vm.prank(deployer);
        bool success = token.transfer(address(0xBEEF), 100e18);
        assertTrue(success);
        vm.prank(address(0xBEEF));
        success = token.transfer(address(0xABCD), 67e18);
        assertTrue(success);

        assertEq(token.balanceOf(address(0xABCD)), 67e18);
        assertEq(token.balanceOf(address(0xBEEF)), 33e18);
        assertEq(token.balanceOf(deployer), 999_900e18);
    }

    function test_transfer_whenNotInsufficientBalance_shouldRevert() public {
        vm.expectRevert("SimpleERC20Token: insufficient balance for transfer");

        vm.prank(deployer);
        token.transfer(address(0xABCD), 1_000_001e18);
    }

    function test_approve() public {
        // precondition
        assertEq(token.allowance(deployer, address(0xBEEF)), 0);

        vm.expectEmit(true, true, true, true);
        emit Events.Approval(deployer, address(0xBEEF), 100e18);

        vm.prank(deployer);
        token.approve(address(0xBEEF), 100e18);

        assertEq(token.allowance(deployer, address(0xBEEF)), 100e18);
    }

    function test_approve_whenMoreThanCurrentBalance() public {
        vm.prank(deployer);
        token.approve(address(0xBEEF), 1_000_001e18);

        // no revert – insufficient balance checks are in transfer() and transferFrom()
    }

    function test_transferFrom() public {
        vm.prank(deployer);
        token.approve(address(0xBEEF), 100e18);

        vm.expectEmit(true, true, true, true);
        emit Events.Transfer(deployer, address(0xABCD), 33e18);

        vm.prank(address(0xBEEF));
        bool success = token.transferFrom(deployer, address(0xABCD), 33e18);

        assertTrue(success);
        assertEq(token.balanceOf(address(0xABCD)), 33e18);
        assertEq(token.balanceOf(deployer), 999_967e18);
        assertEq(token.allowance(deployer, address(0xBEEF)), 67e18); // allowance decreases by transferred amount
    }

    function test_transferFrom_whenInsufficientBalance_shouldRevert() public {
        vm.expectRevert("SimpleERC20Token: insufficient balance for transferFrom");

        vm.prank(address(0xBEEF));
        token.transferFrom(deployer, address(0xABCD), 1_000_001e18);
    }

    function test_transferFrom_whenInsufficientAllowance_shouldRevert() public {
        vm.prank(deployer);
        token.approve(address(0xBEEF), 100e18);

        vm.expectRevert("SimpleERC20Token: insufficient allowance for transferFrom");

        vm.prank(address(0xBEEF));
        token.transferFrom(deployer, address(0xABCD), 101e18);
    }
}

library Events {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SimpleERC20Token {
    //
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public constant totalSupply = 1_000_000 * (uint256(10) ** decimals);

    string public constant name = "Simple ERC20 Token";
    string public constant symbol = "SET";
    uint8 public constant decimals = 18;

    constructor () {
        balanceOf[msg.sender] = totalSupply;
        emit Events.Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "SimpleERC20Token: insufficient balance for transfer");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Events.Transfer(msg.sender, to, value);

        return true;
    }

    /// @dev susceptible to frontrunning attacks – use increase/decrease allowance pattern instead
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Events.Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "SimpleERC20Token: insufficient balance for transferFrom");
        require(allowance[from][msg.sender] >= value, "SimpleERC20Token: insufficient allowance for transferFrom");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Events.Transfer(from, to, value);

        return true;
    }
}
