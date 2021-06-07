
//@ts-ignore
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {LiquidityChanger, INonfungiblePositionManager} from '../typechain'
import { UNISWAP_V3_NFT_POSITION_MANAGER } from './../constants/uniswaps';
import { expect } from 'chai';
describe('Changer :: test get nft token position', () => {
    let deployer, user: SignerWithAddress;
    let charger: LiquidityChanger;
    before(
        'init signers',
        async () => ([deployer, user] = await ethers.getSigners())
    );
    
    before("Changer :: deploy contract", async () => {
        charger = await ethers.getContractFactory("LiquidityChanger").
            then(factory => factory.connect(deployer).
            deploy(UNISWAP_V3_NFT_POSITION_MANAGER)).
            then(contract => contract.deployed().
            then((deployedContract) => deployedContract as LiquidityChanger))
    });
    
    it('Changer :: get NFT Manager Address', async () => {
        expect(await charger.getNftManagerAddress()).to.be.eq(UNISWAP_V3_NFT_POSITION_MANAGER)
    });
    it('Changer :: get token position', async () => {
        let [token0, token1, liquidity] = await charger.getPosition('39455')
        expect(token0).to.be.eq('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48') // USDT
        expect(token1).to.be.eq('0xdAC17F958D2ee523a2206206994597C13D831ec7') // TETHER
        console.log(liquidity.toString())
    })
});