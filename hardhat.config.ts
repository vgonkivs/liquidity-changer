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
           blockNumber: 12670105  , // https://etherscan.io/tx/0x7ff0bb3bd6fd79130244a35783caa089f79ef6e5219a46203d6534835acf24e6
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
