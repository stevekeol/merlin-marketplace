import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  paths: {
      artifacts: "./src",
  },
  networks: {
      merlinTestnet: {
      url: `https://testnet-rpc.merlinchain.io`,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY],
      },
  },
};

export default config;
