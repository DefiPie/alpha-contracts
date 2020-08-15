module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 7545,
      network_id: "*",
      gasPrice: 60000000000
    },
    ropsten: {
      host: "localhost",
      port: 8545,
      network_id: 3,
      gasPrice: 60000000000
    },
    live: {
      host: "localhost",
      port: 8545,
      network_id: 1,
      gasPrice: 50000000000
    },
  },
  compilers: {
    solc: {
      version: "0.6.2",
    },
  },
  plugins: [
    'truffle-contract-size'
  ],
};