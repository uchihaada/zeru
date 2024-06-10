// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/LiquidityProvider.sol";
import "../src/DAIToken.sol";
import "../src/ARBToken.sol";

contract LiquidityProviderTest is Test {
    LiquidityProvider public liquidityProvider;
    DAIToken public dai;
    ARBToken public arb;

    uint256 public mainnet;
    address public owner;
    address public user;
    uint256 public initialSupply = 1000000;
    IUniswapV3Factory public factory;
    INonfungiblePositionManager public positionManager;
    ISwapRouter public swapRouter;

    // string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    function setUp() public {
        // mainnet = vm.createFork(MAINNET_RPC_URL);
        // vm.selectFork(mainnet);

        initAccounts();
        owner = accounts[0].publicKey;
        vm.startPrank(owner);

        dai = new DAIToken(initialSupply);
        arb = new ARBToken(initialSupply);

        liquidityProvider = new LiquidityProvider(address(dai), address(arb));
        emit log_named_uint("", IERC20(address(dai)).balanceOf(owner));
        emit log_named_uint("", IERC20(address(arb)).balanceOf(owner));
        vm.stopPrank();
    }

    // function test() public view {}

    function testCreateAndInitializePool() public {
        vm.startPrank(owner);

        liquidityProvider.createPool(3000);
        address poolAddress = factory.getPool(address(dai), address(arb), 3000);
        assertFalse(poolAddress == address(0), "Pool not found");

        uint160 sqrtPriceX96 = uint160(1 << 96);
        liquidityProvider.initializePool(sqrtPriceX96);

        vm.stopPrank();
    }

    function testProvideLiquidity() public {
        testCreateAndInitializePool();

        vm.startPrank(owner);

        dai.approve(address(liquidityProvider), 500);
        arb.approve(address(liquidityProvider), 500);

        liquidityProvider.provideLiquidity(
            address(dai),
            address(arb),
            3000,
            500,
            500,
            500,
            500,
            -887220,
            887220
        );

        vm.stopPrank();
    }

    function testGetFees() public view {
        uint256 tokenId = 1;
        (uint256 amount0, uint256 amount1) = liquidityProvider.getFees(tokenId);
        console.log("Fees earned: ", amount0, amount1);
    }

    function testPerformSwap() public {
        uint256 amountIn = 100 ether;
        dai.transfer(user, amountIn);
        vm.startPrank(user);
        dai.approve(address(liquidityProvider), amountIn);

        liquidityProvider.performSwap(
            address(swapRouter),
            address(dai),
            address(arb),
            amountIn,
            1 ether
        );

        vm.stopPrank();
    }

    struct UserAccount {
        address publicKey;
        uint256 privateKey;
    }

    UserAccount[] public accounts;

    function initAccounts() internal {
        string
            memory mnemonic = "ecology wealth crystal pear three razor chicken language emotion siren verify leave";
        for (uint8 i = 0; i < 11; i++) {
            uint256 privateKey = vm.deriveKey(mnemonic, i);
            address publicKey = vm.addr(privateKey);
            accounts.push(UserAccount(publicKey, privateKey));
            vm.deal(publicKey, 10000000 ether);
        }
    }
}
