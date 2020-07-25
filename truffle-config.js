module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 7545,
      network_id: "*",
      gasPrice: 130000000000
    }
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