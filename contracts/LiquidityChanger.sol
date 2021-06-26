pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IMulticall.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol';
import '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';

import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol';
import '@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './libraries/PriceMath.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import 'hardhat/console.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

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
    uint160 sqrtRatiox96 = poolPrice(
      position.token0,
      position.token1,
      position.fee
    );
    uint256 price = PriceMath.getPriceAtSqrtRatio(
      position.token1,
      position.token0,
      sqrtRatiox96
    );
    int24 tickSpacing = IUniswapV3PoolImmutables(
      getPoolAddress(position.token0, position.token1, position.fee)
    ).tickSpacing();

    (uint160 minPrice, uint160 maxPrice) = calculateNewLimitPrices(
      position.token0,
      position.token1,
      price,
      _newRange
    );

    bytes[] memory data = new bytes[](2);
    data[0] = abi.encodeWithSignature(
      ('decreaseLiquidity((uint256,uint128,uint256,uint256,uint256))'),
      position.id,
      position.liquidity,
      0,
      0,
      block.timestamp
    );
    data[1] = abi.encodeWithSignature(
      ('collect((uint256,address,uint128,uint128))'),
      position.id,
      address(this),
      type(uint128).max,
      type(uint128).max
    );
    bytes[] memory results = IMulticall(nftManager).multicall(data);
    (position.token0Amount, position.token1Amount) = abi.decode(
      results[1],
      (uint256, uint256)
    );

    IERC20(position.token0).approve(nftManager, position.token0Amount);
    IERC20(position.token1).approve(nftManager, position.token1Amount);
    uint256 token = mintNewToken(position, minPrice, maxPrice, tickSpacing);

    printposition(token);
    console.log(token);
  }

  function poolPrice(
    address token0,
    address token1,
    uint24 fee
  ) private view returns (uint160) {
    (uint160 sqrtPrice, , , , , , ) = IUniswapV3PoolState(
      getPoolAddress(token0, token1, fee)
    ).slot0();
    return sqrtPrice;
  }

  function mintNewToken(
    PositionsData memory params,
    uint160 minPrice,
    uint160 maxPrice,
    int24 tickSpacing
  ) public returns (uint256) {
    (
      uint256 tokenId,
      uint128 _liquidity,
      uint256 amount0,
      uint256 amount1
    ) = INonfungiblePositionManager(nftManager).mint(
      INonfungiblePositionManager.MintParams({
        token0: params.token0,
        token1: params.token1,
        fee: params.fee,
        tickLower: PriceMath.getTickAtSqrtRatioWithFee(maxPrice, tickSpacing),
        tickUpper: PriceMath.getTickAtSqrtRatioWithFee(minPrice, tickSpacing),
        amount0Desired: params.token0Amount,
        amount1Desired: params.token1Amount,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: block.timestamp
      })
    );
    console.log('params.token0Amount', params.token0Amount);
    console.log('params.token1Amount', params.token1Amount);
    console.log('amount0', amount0);
    console.log('amount1', amount1);
    console.log(
      'params.token0Amount after mint',
      params.token0Amount.sub(amount0)
    );
    console.log(
      'params.token1Amount after mint',
      params.token1Amount.sub(amount1)
    );
    console.log('liquidity before ', params.liquidity);
    console.log('liquidity after  ', _liquidity);

    IERC20(params.token0).transfer(
      msg.sender,
      params.token0Amount.sub(amount0)
    );
    IERC20(params.token1).transfer(
      msg.sender,
      params.token1Amount.sub(amount1)
    );

    bytes[] memory data = new bytes[](2);
    data[0] = abi.encodeWithSelector(
      IERC721(nftManager).approve.selector,
      msg.sender,
      tokenId
    );
    data[1] = abi.encodeWithSelector(
      IERC721(nftManager).transferFrom.selector,
      address(this),
      msg.sender,
      tokenId
    );

    IMulticall(nftManager).multicall(data);
    require(IERC721(nftManager).ownerOf(tokenId) == msg.sender);
    return tokenId;
  }

  function calculateNewLimitPrices(
    address token0,
    address token1,
    uint256 currentPrice,
    uint256 range
  ) private view returns (uint160 sqrtPriceMin, uint160 sqrtPriceMax) {
    uint160 sqrtPriceMin = PriceMath.getSqrtRatioAtPrice(
      token1,
      token0,
      currentPrice.sub(range.div(2))
    );

    uint160 sqrtPriceMax = PriceMath.getSqrtRatioAtPrice(
      token1,
      token0,
      currentPrice.add(range.div(2))
    );

    return (sqrtPriceMin, sqrtPriceMax);
  }

  function calculateTokensAmount(
    uint160 sqrtRatioPrice96,
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity
  ) internal returns (uint256, uint256) {
    uint256 token0Amount = SqrtPriceMath.getAmount0Delta(
      sqrtRatioPrice96,
      sqrtRatioBX96,
      liquidity,
      false
    );
    uint256 token1Amount = SqrtPriceMath.getAmount1Delta(
      sqrtRatioAX96,
      sqrtRatioPrice96,
      liquidity,
      false
    );
    return (token0Amount, token1Amount);
  }

  function printposition(uint256 _id) public {
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
    console.log(position.token0);
    console.log(position.token1);
    console.log(position.fee);
    console.log(position.liquidity);
    console.log(uint128(position.tickLower));
    console.log(uint128(position.tickUpper));
  }
}
