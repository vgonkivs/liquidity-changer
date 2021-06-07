import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';

import { HardhatUserConfig } from 'hardhat/types';

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      forking: {
        url:
          'https://eth-mainnet.alchemyapi.io/v2/DMEoI146uTzBp_VdlGhwCVO-5tt7wdWM',
      },
    },
    rinkeby: {
      url: '',
      accounts: {
        mnemonic: '',
      },
    },
  },
  solidity: {
    version: '0.7.6',
    settings: {
      outputSelection: {
        '*': {
          '*': ['storageLayout'],
        },
      },
    },
  },
};
export default config;
