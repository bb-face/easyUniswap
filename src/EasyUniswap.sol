// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EasyUniswap {
    address private constant UNISWAP_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 private uniswapRouter =
        IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    address private constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    IERC20 private usdcToken = IERC20(USDC_ADDRESS);

    address private constant USDC_WETH_POOL_ADDRESS =
        0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    IERC20 private lpToken = IERC20(USDC_WETH_POOL_ADDRESS);

    address private developerAddress;
    uint private constant DEVELOPER_FEE_PERCENT = 1;

    mapping(address => uint) public balances;

    // Constructor to set the developer address
    constructor(address _developerAddress) {
        developerAddress = _developerAddress;
    }

    // Deposit function
    function deposit(uint usdcAmount) external {
        require(
            usdcToken.transferFrom(msg.sender, address(this), usdcAmount),
            "Transfer failed"
        );

        // Calculate developer fee and transfer
        uint developerFee = (usdcAmount * DEVELOPER_FEE_PERCENT) / 100;
        require(
            usdcToken.transfer(developerAddress, developerFee),
            "Fee transfer failed"
        );

        // Adjust USDC amount for swap
        uint amountToSwap = (usdcAmount - developerFee) / 2;

        // Approve Uniswap Router to spend USDC
        usdcToken.approve(UNISWAP_ROUTER_ADDRESS, amountToSwap);

        // Swap half USDC for ETH
        address[] memory path = new address[](2);
        path[0] = USDC_ADDRESS;
        path[1] = uniswapRouter.WETH();

        uniswapRouter.swapExactTokensForETH(
            amountToSwap,
            0, // Set to 0 for simplicity, should be estimated properly to handle slippage
            path,
            address(this),
            block.timestamp
        );

        // Add liquidity to Uniswap
        uint usdcBalance = usdcToken.balanceOf(address(this));
        uint ethBalance = address(this).balance;

        usdcToken.approve(UNISWAP_ROUTER_ADDRESS, usdcBalance);

        (, , uint lpTokenAmount) = uniswapRouter.addLiquidityETH{
            value: ethBalance
        }(
            USDC_ADDRESS,
            usdcBalance,
            0, // Set to 0 for simplicity, should be estimated properly to handle slippage
            0, // Set to 0 for simplicity, should be estimated properly to handle slippage
            address(this),
            block.timestamp
        );
        balances[msg.sender] += lpTokenAmount;
    }

    // Withdraw function
    function withdraw(uint lpTokenAmount) external {
        require(balances[msg.sender] >= lpTokenAmount, "Balance too low");
        balances[msg.sender] -= lpTokenAmount;

        // Approve Uniswap Router to spend LP tokens
        lpToken.approve(UNISWAP_ROUTER_ADDRESS, lpTokenAmount);

        // Remove liquidity
        uniswapRouter.removeLiquidityETH(
            USDC_ADDRESS,
            lpTokenAmount,
            0, // Set to 0 for simplicity, should be estimated properly to handle slippage
            0, // Set to 0 for simplicity, should be estimated properly to handle slippage
            msg.sender, // Funds are sent back to the investor
            block.timestamp
        );
    }

    // Function to receive ETH when swapping
    receive() external payable {}
}
