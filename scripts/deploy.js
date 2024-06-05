const hre = require("hardhat");

async function main() {
  const _signer = "";
  //ezETH, reETH
  const _tokensAllowed = ["0xbf5495Efe5DB9ce00f80364C8B423567e58d2110","0xA1290d69c65A6Fe4DF752f95823fae25cB99e5A7"];
  const _weth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  const LevelMoney = await hre.ethers.getContractFactory("ZtakingPool");
  const levelMoney = await LevelMoney.deploy(_signer, _tokensAllowed, _weth);
  console.log(`deploy SZeta at ${levelMoney.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
