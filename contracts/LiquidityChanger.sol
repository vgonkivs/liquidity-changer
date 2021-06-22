pragma solidity =0.7.6;
pragma abicoder v2;

import {INonfungiblePositionManager} from '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import {IUniswapV3Factory} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {IUniswapV3PoolState} from '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolImmutables} from '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol';
import {PoolAddress} from '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';

import {TickMath} from '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import {LiquidityAmounts} from '@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol';
import {SqrtPriceMath} from '@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol';
import {TokensAmount} from './libraries/TokensAmount.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {PriceMath} from './libraries/PriceMath.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import 'hardhat/console.sol';

contract LiquidityChanger {
  using SafeMath for uint256;
  address private immutable nftManager;
  address private immutable uniswapV3Factory;

  constructor(address _nftManager, address _factory) public {
    nftManager = _nftManager;
    uniswapV3Factory = _factory;
  }

  struct PositionsData {
    uint256 id;
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidity;
    uint256 token0Amount;
    uint256 token1Amount;
  }

  function getNftManagerAddress() external view returns (address) {
    return nftManager;
  }

  function getTokensAmountsFromPosition(uint256 _id)
    public
    view
    returns (uint256 token0Amount, uint256 token1Amount)
  {
    (
      ,
      ,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      ,
      ,
      ,

    ) = INonfungiblePositionManager(nftManager).positions(_id);
    (, int24 poolTick, , , , , ) = IUniswapV3PoolState(
      getPoolAddress(token0, token1, fee)
    ).slot0();
    return
      TokensAmount.getAmountsFromPosition(
        liquidity,
        tickLower,
        tickUpper,
        poolTick
      );
  }

  function getPoolAddress(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) private view returns (address) {
    PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({
      token0: _tokenA,
      token1: _tokenB,
      fee: _fee
    });
    return PoolAddress.computeAddress(uniswapV3Factory, poolKey);
  }

  function changePriceRange(uint256 _id, uint256 _newRange) external {
    require(
      INonfungiblePositionManager(nftManager).getApproved(_id) == address(this),
      'Token should be approved'
    );

    PositionsData memory position;
    (
      ,
      ,
      position.token0,
      position.token1,
      position.fee,
      position.tickLower,
      position.tickUpper,
      position.liquidity,
      ,
      ,
      ,

    ) = INonfungiblePositionManager(nftManager).positions(_id);
    position.id = _id;

    int24 poolTick = poolTick(position.token0, position.token1, position.fee);
    uint256 price = PriceMath.getPriceAtSqrtRatio(
      position.token1,
      position.token0,
      TickMath.getSqrtRatioAtTick(poolTick)
    );
    int24 tickSpacing = IUniswapV3PoolImmutables(
      getPoolAddress(position.token0, position.token1, position.fee)
    ).tickSpacing();

    (uint256 minPrice, uint256 maxPrice) = TokensAmount.calculateNewLimitPrices(
      price,
      _newRange
    );

    (position.token0Amount, position.token1Amount) = TokensAmount
    .getAmountsFromPosition(
      position.liquidity,
      position.tickLower,
      position.tickUpper,
      poolTick
    );
    removeLiquidityAndGetTokens(position);

    uint256 token = mintNewToken(position, minPrice, maxPrice, tickSpacing);
    console.log(token);
  }

  function removeLiquidityAndGetTokens(PositionsData memory params) public {
    INonfungiblePositionManager(nftManager).decreaseLiquidity(
      INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: params.id,
        liquidity: params.liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
      })
    );

    (params.token0Amount, params.token1Amount) = INonfungiblePositionManager(
      nftManager
    ).collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: params.id,
        recipient: address(this),
        amount0Max: uint128(params.token0Amount),
        amount1Max: uint128(params.token1Amount)
      })
    );
  }

  function poolTick(
    address token0,
    address token1,
    uint24 fee
  ) private view returns (int24) {
    (, int24 poolTick, , , , , ) = IUniswapV3PoolState(
      getPoolAddress(token0, token1, fee)
    ).slot0();
    return poolTick;
  }

  function mintNewToken(
    PositionsData memory params,
    uint256 minPrice,
    uint256 maxPrice,
    int24 tickSpacing
  ) public returns (uint256) {
    IERC20(params.token0).approve(nftManager, params.token0Amount);
    IERC20(params.token1).approve(nftManager, params.token1Amount);

    uint160 sqrtPriceMin = PriceMath.getSqrtRatioAtPrice(
      params.token1,
      params.token0,
      minPrice
    );

    uint160 sqrtPriceMax = PriceMath.getSqrtRatioAtPrice(
      params.token1,
      params.token0,
      maxPrice
    );

    (
      uint256 tokenId,
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    ) = INonfungiblePositionManager(nftManager).mint(
      INonfungiblePositionManager.MintParams({
        token0: params.token0,
        token1: params.token1,
        fee: params.fee,
        tickLower: PriceMath.getTickAtSqrtRatioWithFee(
          sqrtPriceMax,
          tickSpacing
        ),
        tickUpper: PriceMath.getTickAtSqrtRatioWithFee(
          sqrtPriceMin,
          tickSpacing
        ),
        amount0Desired: params.token0Amount,
        amount1Desired: params.token1Amount,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: block.timestamp
      })
    );

    IERC20(params.token0).transfer(
      msg.sender,
      params.token0Amount.sub(amount0)
    );
    IERC20(params.token1).transfer(
      msg.sender,
      params.token1Amount.sub(amount1)
    );

    return tokenId;
  }
}
