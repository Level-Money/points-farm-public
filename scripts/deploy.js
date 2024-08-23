const hre = require("hardhat");

const args = {
  mainnet: {
    signer: "0x343ACce723339D5A417411D8Ff57fde8886E91dc",
    tokensAllowed: [
      // USDT
      "0xdac17f958d2ee523a2206206994597c13d831ec7",
    ],
    limits: [500_000_000_000], // 500k USDT
    weth: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
  },
  sepolia: {
    signer: "0xe9AF0428143E4509df4379Bd10C4850b223F2EcB",
    tokensAllowed: [
      // Sepolia USDC
      "0xf08a50178dfcde18524640ea6618a1f965821715",
    ],
    limits: [1],
    weth: "0x7b79995e5f793a07bc00c21412e50ecae098e7f9",
  },
};

async function main() {
  const network = hre.network.name;
  console.log(`deploying on ${network} network`);

  const [_signer, _tokensAllowed, _limits, _weth] = [
    args[network].signer,
    args[network].tokensAllowed,
    args[network].limits,
    args[network].weth,
  ];

  const LevelMoney = await hre.ethers.getContractFactory("LevelStakingPool");
  const levelMoney = await LevelMoney.deploy(
    _signer,
    _tokensAllowed,
    _limits,
    _weth
  );

  await levelMoney.waitForDeployment();

  console.log(`Deployed Level Money at ${levelMoney.target}`);

  console.log(`Verifying...`);
  await hre.run("verify:verify", {
    address: levelMoney.target,
    constructorArguments: [_signer, _tokensAllowed, _limits, _weth],
  });
  console.log(`Verified!`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
