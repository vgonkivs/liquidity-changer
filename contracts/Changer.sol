pragma solidity =0.7.6;

import {
  INonfungiblePositionManager
} from '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

import {
  PoolAddress
} from '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import {
  IUniswapV3Factory
} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import {
  IUniswapV3Pool
} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {
  IUniswapV3PoolState
} from '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol';
import {
  TickMath
} from '@uniswap/v3-core/contracts/libraries/TickMath.sol';

import {
  SqrtPriceMath
} from '@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol';
import "hardhat/console.sol";

contract LiquidityChanger {
    address private immutable nftManager;
    address private immutable uniswapV3Factory;

    constructor(address _nftManager, address _factory) public {
        nftManager = _nftManager;
        uniswapV3Factory = _factory;
    }
    struct Position {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint128 tokensOwned0;
        uint128 tokensOwned1;
    }

    function changePriceRange(uint256 _id, uint256 newRange) external view returns(uint256, uint256){
        ( , , address token0, address token1, uint24 fee, , , uint128 liquidity, , , , ) = INonfungiblePositionManager(nftManager).positions(_id);
        uint256 currentPrice = getCurrentPrice(token0, token1, fee, getPoolAddress(token0, token1, fee));
        return (calculateMinPrice(currentPrice, newRange), calculateMaxPrice(currentPrice, newRange));
    }

    function getNftManagerAddress() external view returns(address){
        return nftManager;
    }

    function getPoolAddress(
    address _tokenA,
    address _tokenB,
    uint24 _fee
    ) private view returns (address) {
    PoolAddress.PoolKey memory poolKey =
      PoolAddress.PoolKey({token0: _tokenA, token1: _tokenB, fee: _fee});
    return PoolAddress.computeAddress(uniswapV3Factory, poolKey);
    }

    function calculateMinPrice(uint256 currentPrice, uint256 range) private view returns(uint256) {
        uint256 minPrice = currentPrice - range/2;
        return minPrice;
    }

    function calculateMaxPrice(uint256 currentPrice, uint256 range) private view returns(uint256) {
        uint256 maxPrice = currentPrice + range/2;
        return maxPrice;
    }

    function getTick(uint256 _id) external view returns(int24 tickLower, int24 tickUpper){
      ( , , , , , tickLower, tickUpper, , , , , ) = INonfungiblePositionManager(nftManager).positions(_id);
    }

 function getCurrentPrice(address tokenIn, address tokenOut, uint24 fee, address pool)
        public
        view
        returns (uint256 price)
    {
        (,int24 poolTick,,,,,) =  IUniswapV3Pool(pool).slot0();
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(poolTick);
        return uint(sqrtPriceX96) * (uint(sqrtPriceX96)) * (1 ether) >> (96 * 2);
    }
}