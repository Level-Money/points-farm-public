module.exports = {
    //contracts_directory: './contracts',
    //contracts_build_directory: './output',
    //migrations_directory: './migrations',
    networks: {
      development: {
        privateKey: "redacted",
        userFeePercentage: 100, // The percentage of resource consumption ratio.
        feeLimit: 100000000, // The TRX consumption limit for the deployment and trigger, unit is SUN
        fullNode: 'https://api.nileex.io',
        solidityNode: 'https://api.nileex.io',
        eventServer: 'https://event.nileex.io',
        network_id: '*'
      },
      compilers: {
        solc: {
          version: '0.8.20'
        }
      }
    },
     // solc compiler optimize
    solc: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      evmVersion: 'istanbul'
    }
  };