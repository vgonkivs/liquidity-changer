pragma solidity =0.7.6;

import {
  INonfungiblePositionManager
} from '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

contract LiquidityChanger {
    address private immutable nftManager;

    constructor(address _nftManager) public {
        nftManager = _nftManager;
    }

    function getPosition(uint256 _id) public view {
        (uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1) = INonfungiblePositionManager(nftManager).positions(_id);
    }
}

