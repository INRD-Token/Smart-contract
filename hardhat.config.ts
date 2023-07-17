import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "solidity-coverage";
import "@openzeppelin/hardhat-upgrades";
import { HardhatUserConfig, NetworksUserConfig } from "hardhat/types";
import Env from "dotenv";
import "@nomiclabs/hardhat-etherscan";
import "@fireblocks/hardhat-fireblocks";
import "@openzeppelin/hardhat-upgrades";

Env.config({ path: "./.secrets.env" });

const hardhatConfig: HardhatUserConfig = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    sepoliaDirect: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.SEPOLI_ALCHEMY_APIKEY}`,
      accounts: process.env.SEPOLI_DEPLOYER_PRIVATE_KEY
        ? [process.env.SEPOLI_DEPLOYER_PRIVATE_KEY]
        : undefined,
      chainId: 11155111,
    },
    sepoliaFB: {
      url: `https://rpc2.sepolia.org`,
      fireblocks: {
        privateKey: process.env.SEPOLI_FIREBLOCKS_API_SECRET_PATH_DEPLOYER,
        apiKey: process.env.SEPOLI_FIREBLOCKS_API_KEY_DEPLOYER,
        vaultAccountIds:
          process.env.SEPOLI_FIREBLOCKS_VAULT_ACCOUNT_ID_DEPLOYER,
      },
    },
    mainnetFB: {
      url: "https://rpc.ankr.com/eth",
      fireblocks: {
        privateKey: process.env.MAINNET_FIREBLOCKS_API_SECRET_PATH_DEPLOYER,
        apiKey: process.env.MAINNET_FIREBLOCKS_API_KEY_DEPLOYER,
        vaultAccountIds:
          process.env.MAINNET_FIREBLOCKS_VAULT_ACCOUNT_ID_DEPLOYER,
      },
    },
  },
  typechain: {
    outDir: "typechain/inrd",
    target: "ethers-v5",
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_APIKEY,
      goerli: process.env.ETHERSCAN_APIKEY,
      sepolia: process.env.ETHERSCAN_APIKEY,
    },
  },
  mocha: {
    timeout: 0,
  },
};

export default hardhatConfig;
