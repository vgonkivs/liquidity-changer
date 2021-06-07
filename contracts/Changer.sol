pragma solidity =0.7.6;

import {
  INonfungiblePositionManager
} from '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

contract LiquidityChanger {
    address private immutable nftManager;

    constructor(address _nftManager) public {
        nftManager = _nftManager;
    }

    function getPosition(uint256 _id) public view returns(address, address, uint128){
        ( , , address token0, address token1, , , , uint128 liquidity, , , , ) = INonfungiblePositionManager(nftManager).positions(_id);
        return (token0, token1, liquidity);

    }

    function getNftManagerAddress() external view returns(address){
        return nftManager;
    }
}

