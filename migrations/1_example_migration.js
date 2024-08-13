var MyContract = artifacts.require('./LevelStakingPool.sol');

module.exports = function (deployer) {
  deployer.deploy(MyContract,
    "TSKRuchx7iyQZucrmXNhk3wPmRNP1L2mZk",
    [
    "TG3XXyExBkPp9nzdajDZsozEu4BkaSJozs" // shasta usdt
   ],
   [100000000000000],
   "TG3XXyExBkPp9nzdajDZsozEu4BkaSJozs" // WETH
);
};