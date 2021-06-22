pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

library TokensAmount {
  using SafeMath for uint256;

  function getAmountsFromPosition(
    uint128 liquidity,
    int24 tickLower,
    int24 tickUpper,
    int24 poolTick
  ) internal view returns (uint256 token0Amount, uint256 token1Amount) {
    token0Amount = TokensAmount.token0Amount(
      liquidity,
      poolTick,
      tickLower,
      tickUpper
    );
    token1Amount = TokensAmount.token1Amount(
      liquidity,
      poolTick,
      tickLower,
      tickUpper
    );
    return (token0Amount, token1Amount);
  }

  /**
   * @dev Get ALPHR amount for NFT
   */
  function token0Amount(
    uint128 positionLiquidity,
    int24 poolCurrentTick,
    int24 positionTickLower,
    int24 positionTickUpper
  ) internal view returns (uint256 amount) {
    if (poolCurrentTick < positionTickLower) {
      return
        SqrtPriceMath.getAmount0Delta(
          TickMath.getSqrtRatioAtTick(positionTickLower),
          TickMath.getSqrtRatioAtTick(positionTickUpper),
          positionLiquidity,
          false
        );
    } else if (poolCurrentTick < positionTickUpper) {
      return
        SqrtPriceMath.getAmount0Delta(
          TickMath.getSqrtRatioAtTick(poolCurrentTick),
          TickMath.getSqrtRatioAtTick(positionTickUpper),
          positionLiquidity,
          false
        );
    } else {
      return 0;
    }
  }

  /**
   * @dev Get ETH amount for NFT
   */
  function token1Amount(
    uint128 positionLiquidity,
    int24 poolCurrentTick,
    int24 positionTickLower,
    int24 positionTickUpper
  ) internal pure returns (uint256 amount) {
    if (poolCurrentTick < positionTickLower) {
      return 0;
    } else if (poolCurrentTick < positionTickUpper) {
      return
        SqrtPriceMath.getAmount1Delta(
          TickMath.getSqrtRatioAtTick(positionTickLower),
          TickMath.getSqrtRatioAtTick(poolCurrentTick),
          positionLiquidity,
          false
        );
    } else {
      return
        SqrtPriceMath.getAmount1Delta(
          TickMath.getSqrtRatioAtTick(positionTickLower),
          TickMath.getSqrtRatioAtTick(positionTickUpper),
          positionLiquidity,
          false
        );
    }
  }

  function calculateNewLimitPrices(uint256 currentPrice, uint256 range)
    internal
    pure
    returns (uint256 minPrice, uint256 maxPrice)
  {
    uint256 minPrice = currentPrice - range / 2;
    uint256 maxPrice = currentPrice + range / 2;
    return (minPrice, maxPrice);
  }
}
