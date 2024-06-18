// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract LiquidityProvider is IERC721Receiver {
    address public owner;
    INonfungiblePositionManager public positionManager;
    IUniswapV3Factory public factory;
    ISwapRouter public swapRouter;
    IERC20 public dai;
    IERC20 public arb;
    IUniswapV3Pool public pool;
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    mapping(uint256 => Deposit) public deposits;

    constructor(address _dai, address _arb) {
        owner = msg.sender;
        factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        positionManager = INonfungiblePositionManager(
            0xC36442b4a4522E871399CD717aBDD847Ab11FE88
        );
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        dai = IERC20(_dai);
        arb = IERC20(_arb);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function createPool(uint24 fee) external onlyOwner {
        address poolAddress = factory.createPool(
            address(dai),
            address(arb),
            fee
        );
        pool = IUniswapV3Pool(poolAddress);
    }

    function initializePool(uint160 sqrtPriceX96) external onlyOwner {
        pool.initialize(sqrtPriceX96);
    }

    function provideLiquidity(
        address token0,
        address token1,
        uint24 fee,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min,
        int24 tickLower,
        int24 tickUpper
    ) external onlyOwner returns (uint256 tokenId) {
        // Transfer tokens to this contract
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        // Approve tokens for the position manager
        IERC20(token0).approve(address(positionManager), amount0);
        IERC20(token1).approve(address(positionManager), amount1);

        // Provide liquidity and receive NFT position
        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: address(dai),
                token1: address(arb),
                fee: fee,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, , , ) = positionManager.mint(params);

        // Store the tokenId if needed
        return tokenId;
    }

    // Function to get fees earned by simulating the collect() call
    function getFees(
        uint256 tokenId
    ) external view returns (uint256 amount0, uint256 amount1) {
        // Simulate the collect call
        (, , , , , , , , , , amount0, amount1) = positionManager.positions(
            tokenId
        );

        return (amount0, amount1);
    }

    // Function to perform swaps to generate fees
    function performSwap(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    ) external {
        // Approve token transfer to the router
        IERC20(tokenIn).approve(router, amountIn);

        // Execute the swap
        ISwapRouter(router).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: 100,
                recipient: msg.sender,
                deadline: block.timestamp + 300,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        // get position information

        _createDeposit(operator, tokenId);

        return this.onERC721Received.selector;
    }

    function _createDeposit(address own, uint256 tokenId) internal {
        (
            ,
            ,
            address token0,
            address token1,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = positionManager.positions(tokenId);

        // set the owner and data for position
        // operator is msg.sender
        deposits[tokenId] = Deposit({
            owner: own,
            liquidity: liquidity,
            token0: token0,
            token1: token1
        });
    }
}
