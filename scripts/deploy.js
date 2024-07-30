const hre = require("hardhat");

const args = {
  mainnet: {
    signer: "0x343ACce723339D5A417411D8Ff57fde8886E91dc",
    tokensAllowed: [
      // stETH
      "0xae7ab96520de3a18e5e111b5eaab095312d7fe84",
      // Renzo ETH
      "0xbf5495Efe5DB9ce00f80364C8B423567e58d2110",
      // Kelp ETH
      "0xA1290d69c65A6Fe4DF752f95823fae25cB99e5A7",
      // USDC
      "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
      // USDT
      "0xdac17f958d2ee523a2206206994597c13d831ec7",
      // DAI
      "0x6b175474e89094c44da98b954eedeac495271d0f",
      // sDAI
      "0x83f20f44975d03b1b09e64809b757c47f942beea",
      // USDe
      "0x4c9edd5852cd905f086c759e8383e09bff1e68b3",
      // sUSDe
      "0x9D39A5DE30e57443BfF2A8307A4256c8797A3497",
    ],
    weth: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
  },
  sepolia: {
    signer: "0xe9AF0428143E4509df4379Bd10C4850b223F2EcB",
    tokensAllowed: [
      // Sepolia USDC
      "0xf08a50178dfcde18524640ea6618a1f965821715",
    ],
    weth: "0x7b79995e5f793a07bc00c21412e50ecae098e7f9",
  },
};
async function main() {
  const network = hre.network.name;
  console.log(`deploying on ${network} network`);

  const [_signer, _tokensAllowed, _weth] = [
    args[network].signer,
    args[network].tokensAllowed,
    args[network].weth,
  ];

  const LevelMoney = await hre.ethers.getContractFactory("LevelStakingPool");
  const levelMoney = await LevelMoney.deploy(_signer, _tokensAllowed, _weth);

  await levelMoney.waitForDeployment();

  console.log(`Deployed Level Money at ${levelMoney.target}`);

  console.log(`Verifying...`);
  await hre.run("verify:verify", {
    address: levelMoney.target,
    constructorArguments: [_signer, _tokensAllowed, _weth],
  });
  console.log(`Verified!`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
