// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0; 
 
import “@openzeppelin/contracts/token/ERC20/IERC20.sol”; 
import “@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol”; 
import “@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol”; 
import “@sushiswap/core/contracts/uniswapv2/libraries/UniswapV2Library.sol”; 
import “@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol”; 
import “@apeswap/apeswap-lib/contracts/interfaces/IApeRouter02.sol”; 
import “@polydex-finance/polydex-core/contracts/interfaces/IPolydexPair.sol”; 
import “@quickswap/quickswap-core/contracts/interfaces/IUniswapV2Pair.sol”; 
import “@quickswap/quickswap-core/contracts/interfaces/IQuickswapV2Router02.sol”; 
 
interface IWETH { 
function deposit() external payable; 
function transfer(address to, uint value) external returns (bool); 
function withdraw(uint) external; 
} 
 
contract Swap { 
address private constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564; 
address private constant UNISWAP_V3_NFT_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88; 
address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 
address private constant SUSHISWAP_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; 
address private constant APESWAP_ROUTER = 0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607; 
address private constant POLYDEX_FACTORY = 0x8f7F78080219d4066A8036ccD30D588B416a40DB; 
address private constant QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; 
 
function swapWMATICtoWETH( 
uint256 amount, 
uint256 minAmountOut, 
address recipient, 
uint24 uniswapV3Fee, 
uint256 sushiswapDeadline, 
uint256 apeswapDeadline, 
uint256 polydexDeadline, 
uint256 quickswapDeadline 
) external { 
// Approve all tokens to their respective routers 
IERC20(WMATIC_ADDRESS).approve(UNISWAP_V3_ROUTER, type(uint256).max); 
IERC20(WMATIC_ADDRESS).approve(UNISWAP_V2_ROUTER, type(uint256).max); 
IERC20(WMATIC_ADDRESS).approve(SUSHISWAP_ROUTER, type(uint256).max); 
IERC20(WMATIC_ADDRESS).approve(APESWAP_ROUTER, type(uint256).max); 
IERC20(WMATIC_ADDRESS).approve(POLYDEX_FACTORY, type(uint256).max); 
IERC20(WMATIC_ADDRESS).approve(QUICKSWAP_ROUTER, type(uint256).max); 
IERC20(WETH_ADDRESS).approve(UNISWAP_V3_ROUTER, type(uint256).max); 
IERC20(WETH_ADDRESS).approve(UNISWAP_V2_ROUTER, type(uint256).max); 
IERC20(WETH_ADDRESS).approve(SUSHISWAP_ROUTER, type(uint256).max); 
IERC20(WETH_ADDRESS).approve(APESWAP_ROUTER, type(uint256).max); 
IERC20(WETH_ADDRESS).approve(POLYDEX_FACTORY, type(uint256).max); 
IERC20(WETH_ADDRESS).approve(QUICKSWAP_ROUTER, type(uint256).max); 
 
// Swap on Uniswap v3 
ISwapRouter.ExactInputSingleParams memory uniswapV3Params = ISwapRouter.ExactInputSingleParams({ 
tokenIn: WMATIC_ADDRESS, 
tokenOut: WETH_ADDRESS, 
fee: uniswapV3Fee, 
recipient: address(this), 
deadline: block.timestamp + 300, 
amountIn: amount, 
amountOutMinimum: minAmountOut, 
sqrtPriceLimitX96: 0 
}); 
TransferHelper.safeApprove(WMATIC_ADDRESS, UNISWAP_V3_ROUTER, amount); 
ISwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(uniswapV3Params); 
 
// Swap on Uniswap v2 
address[] memory uniswapV2Path = UniswapV2Library.getPath(WMATIC_ADDRESS, WETH_ADDRESS); 
IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens( 
amount, 
minAmountOut, 
uniswapV2Path, 
address(this), 
block.timestamp + 300 
); 
 
// Swap on Sushiswap 
address[] memory sushiswapPath = UniswapV2Library.getPath(WMATIC_ADDRESS, WETH_ADDRESS); 
IUniswapV2Router02(SUSHISWAP_ROUTER).swapExactTokensForTokens( 
amount, 
minAmountOut, 
sushiswapPath, 
address(this), 
sushiswapDeadline 
); 
 
// Swap on ApeSwap 
address[] memory apeswapPath = new address; 
apeswapPath[0] = WMATIC_ADDRESS; 
apeswapPath[1] = WETH_ADDRESS; 
IApeRouter02(APESWAP_ROUTER).swapExactTokensForTokens( 
amount, 
minAmountOut, 
apeswapPath, 
address(this), 
apeswapDeadline 
); 
 
// Swap on Polydex 
address polydexPairAddress = IPolydexFactory(POLYDEX_FACTORY).getPair(WMATIC_ADDRESS, WETH_ADDRESS); 
require(polydexPairAddress != address(0), “Polydex: pair does not exist”); 
IPolydexPair(polydexPairAddress).swap( 
amount, 
minAmountOut, 
address(this), 
bytes(“not empty”), 
polydexDeadline 
); 
 
// Swap on Quickswap v3 
ISwapRouter.ExactInputSingleParams memory quickswapV3Params = ISwapRouter.ExactInputSingleParams({ 
tokenIn: WMATIC_ADDRESS, 
tokenOut: WETH_ADDRESS, 
fee: 3000, 
recipient: address(this), 
deadline: block.timestamp + 300, 
amountIn: amount, 
amountOutMinimum: minAmountOut, 
sqrtPriceLimitX96: 0 
}); 
TransferHelper.safeApprove(WMATIC_ADDRESS, QUICKSWAP_ROUTER, amount); 
IQuickswapV2Router02(QUICKSWAP_ROUTER).exactInputSingle(quickswapV3Params); 
 
// Swap back to WMATIC 
uint256 wethBalance = IERC20(WETH_ADDRESS).balanceOf(address(this)); 
IWETH(WETH_ADDRESS).withdraw(wethBalance); 
 
// Swap on Uniswap v3 
ISwapRouter.ExactInputSingleParams memory uniswapV3ParamsBack = ISwapRouter.ExactInputSingleParams({ 
tokenIn: WETH_ADDRESS, 
tokenOut: WMATIC_ADDRESS, 
fee: uniswapV3Fee, 
recipient: recipient, 
deadline: block.timestamp + 300, 
amountIn: wethBalance, 
amountOutMinimum: 0, 
sqrtPriceLimitX96: 0 
}); 
TransferHelper.safeApprove(WETH_ADDRESS, UNISWAP_V3_ROUTER, wethBalance); 
ISwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(uniswapV3ParamsBack); 
 
// Swap on Uniswap v2 
address[] memory uniswapV2PathBack = UniswapV2Library.getPath(WETH_ADDRESS, WMATIC_ADDRESS); 
IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens( 
wethBalance, 
0, 
uniswapV2PathBack, 
recipient, 
block.timestamp + 300 
); 
 
// Swap on Sushiswap 
address[] memory sushiswapPathBack = UniswapV2Library.getPath(WETH_ADDRESS, WMATIC_ADDRESS); 
IUniswapV2Router02(SUSHISWAP_ROUTER).swapExactTokensForTokens( 
wethBalance, 
0, 
sushiswapPathBack, 
recipient, 
sushiswapDeadline 
); 
 
// Swap on ApeSwap 
address[] memory apeswapPathBack = new address; 
apeswapPathBack[0] = WETH_ADDRESS; 
apeswapPathBack[1] = WMATIC_ADDRESS; 
IApeRouter02(APESWAP_ROUTER).swapExactTokensForTokens( 
wethBalance, 
0, 
apeswapPathBack, 
recipient, 
apeswapDeadline 
); 
 
