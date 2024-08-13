require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  // Sepolia: 11155111
  // Mainnet: 1
  defaultNetwork: "sepolia",
  networks: {
    sepolia: {
      //url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      //accounts: [`${process.env.PRIVATE_KEY}`],
      url: "https://eth-sepolia.api.onfinality.io/public",
      accounts: ['7b061eceb7b1d0e81fdd4eeecbc002e95bfb0c5be4f9964c7e5df8d1b099f785']
    },
    mainnet: {
      url: "https://eth-sepolia.api.onfinality.io/public",
      accounts: ['7b061eceb7b1d0e81fdd4eeecbc002e95bfb0c5be4f9964c7e5df8d1b099f785']
    },
  },
  etherscan: {
    apiKey: `${process.env.ETHERSCAN_API_KEY}`,
  },
};
