import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import '@typechain/hardhat';

import { HardhatUserConfig } from 'hardhat/types';

const OPTIMIZER_COMPILER_SETTINGS = {
  version: '0.7.6',
  settings: {
    optimizer: {
      enabled: true,
      runs: 2_000,
    },
    metadata: {
      bytecodeHash: 'none',
    },
  },
}

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      forking: {
        url:
          'https://eth-mainnet.alchemyapi.io/v2/DMEoI146uTzBp_VdlGhwCVO-5tt7wdWM',
           blockNumber: 12670105  , // https://etherscan.io/tx/0x30ba41af8432c3e5260b1fce195b4c507c9d51463b760a2f2d9a8ddba70b582c
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
    compilers: [OPTIMIZER_COMPILER_SETTINGS],
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
