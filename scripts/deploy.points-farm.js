const hre = require("hardhat");

const args = {
  mainnet: {
    initialOwner: "0x343ACce723339D5A417411D8Ff57fde8886E91dc",
  },
  sepolia: {
    initialOwner: "0xe9AF0428143E4509df4379Bd10C4850b223F2EcB",
  },
};

async function main() {
  const network = hre.network.name;
  console.log(`deploying points farm on ${network} network`);

  const [_initialOwner] = [args[network].initialOwner];

  const LevelMoney = await hre.ethers.getContractFactory("LevelUsdPointsFarm");
  const levelMoney = await LevelMoney.deploy(_initialOwner);

  await levelMoney.waitForDeployment();

  console.log(`Deployed Level Money at ${levelMoney.target}`);

  console.log(`Verifying...`);
  await hre.run("verify:verify", {
    address: levelMoney.target,
    constructorArguments: [_initialOwner],
  });
  console.log(`Verified!`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
