require("@nomicfoundation/hardhat-toolbox");
require("@layerzerolabs/hardhat-deploy");
require("@layerzerolabs/hardhat-tron");

require("dotenv").config();
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  defaultNetwork: "sepolia",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [`${process.env.PRIVATE_KEY}`],
    },
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [`${process.env.PRIVATE_KEY}`],
    },
    shasta: {
      url: "https://api.shasta.trongrid.io/jsonrpc",
      accounts: [process.env.TRON_PRIVATE_KEY],
      httpHeaders: { "TRON-PRO-API-KEY": process.env.TRON_PRO_API_KEY },
      tron: true,
    },
    tron: {
      url: "https://api.trongrid.io/jsonrpc",
      accounts: [process.env.TRON_PRIVATE_KEY],
      httpHeaders: { "TRON-PRO-API-KEY": process.env.TRON_PRO_API_KEY },
      tron: true,
    },
  },
  etherscan: {
    apiKey: `${process.env.ETHERSCAN_API_KEY}`,
  },
  tronSolc: {
    enable: true,
    compilers: [{ version: "0.8.20" }], // can be any tron-solc version
    versionRemapping: [
      ["0.8.24", "0.8.20"], // Remap version "0.8.20" to "0.8.19"
    ],
  },
};
