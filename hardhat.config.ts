import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';

import { HardhatUserConfig } from 'hardhat/types';

const config: HardhatUserConfig = {
  // networks: {
  //   hardhat: {
  //     forking: {
  //       url:
  //         'https://eth-mainnet.alchemyapi.io/v2/iHddcEw1BVe03s2BXSQx_r_BTDE-jDxB',
  //       blockNumber: 12472213, //  DO NOT CHANGE!
  //     },
  //   },
  //   rinkeby: {
  //     url: '',
  //     accounts: {
  //       mnemonic: '',
  //     },
  //   },
  // },
  solidity: {
    version: '0.8.0',
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
