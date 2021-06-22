//@ts-ignore
import { ethers, network, provider } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {LiquidityChanger, INonfungiblePositionManager} from '../typechain'
import { UNISWAP_V3_NFT_POSITION_MANAGER, UNISWAP_V3_FACTORY } from './../constants/uniswaps';
import {utils } from 'ethers';
import { expect } from 'chai';

describe('Changer :: test get nft token position', () => {
    let deployer, user: SignerWithAddress;
    let nonFungibleManager: INonfungiblePositionManager;
    let charger : LiquidityChanger
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
        nonFungibleManager = (await ethers.getContractAt(
            'INonfungiblePositionManager',
            UNISWAP_V3_NFT_POSITION_MANAGER
        )) as INonfungiblePositionManager;
    });
    
    it('Changer :: get NFT Manager Address', async () => {
        expect(await charger.getNftManagerAddress()).to.be.eq(UNISWAP_V3_NFT_POSITION_MANAGER)
    });

    it('Changer :: change price range', async () => {
        const tokenHolderAddress = '0xfbb48991d7a776f628f1b62dffb9d265a6badeed';
        await network.provider.send('hardhat_impersonateAccount', [
        tokenHolderAddress,
        ]);

        await (
            await user.sendTransaction({
                from: user.address,
                to: tokenHolderAddress,
                value: utils.parseEther('10'),
            })
        ).wait();

        const tokenHolder = await ethers.provider.getSigner(tokenHolderAddress);
        await nonFungibleManager.connect(tokenHolder).approve(charger.address, '54390');
        
        await charger.connect(tokenHolder).changePriceRange('54390', utils.parseEther('0.00000000003'), { gasLimit: 12450000 })
   });
});