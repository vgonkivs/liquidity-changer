import { utils } from 'ethers';

//@ts-ignore
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {LiquidityChanger, INonfungiblePositionManager} from '../typechain'
import { UNISWAP_V3_NFT_POSITION_MANAGER, UNISWAP_V3_FACTORY } from './../constants/uniswaps';
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
            deploy(UNISWAP_V3_NFT_POSITION_MANAGER, UNISWAP_V3_FACTORY)).
            then(contract => contract.deployed().
            then((deployedContract) => deployedContract as LiquidityChanger))
    });
    
    it('Changer :: get NFT Manager Address', async () => {
        expect(await charger.getNftManagerAddress()).to.be.eq(UNISWAP_V3_NFT_POSITION_MANAGER)
    });
    it('Changer :: get token position', async () => {
        let [minPrice,maxPrice] = await charger.changePriceRange('39455', utils.parseEther('1'))
        expect(minPrice.toString()).to.be.eq('499600099980003499')
        expect(maxPrice.toString()).to.be.eq('1499600099980003499')
    })
});