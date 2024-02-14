// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./MyWETHInterface.sol";

error MyWETH__NotEnoughFunds();
error MyWETH__TransactionFailed();

contract MyWETH is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "wrapped Ethereum";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;

        emit Transfer(address(0), msg.sender, msg.value);
    }

    // not needed
    function burn() external payable {
        balanceOf[msg.sender] -= msg.value;
        totalSupply -= msg.value;

        (bool success, ) = address(0).call{value: msg.value}("");

        emit Transfer(msg.sender, address(0), msg.value);
    }

    function withdraw(uint256 amount) external {
        if (balanceOf[msg.sender] < amount) revert MyWETH__NotEnoughFunds();

        balanceOf[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");

        if (!success) revert MyWETH__TransactionFailed();
    }

    // Better throw an error if someone send money by mistake
    // receive() external payable {
    //     this.deposit();
    // }
}
