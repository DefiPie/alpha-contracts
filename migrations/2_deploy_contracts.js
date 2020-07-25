const PeerToPeerLending = artifacts.require("../contracts/PeerToPeerLending.sol");
//const USDC = artifacts.require("../contracts/USDC.sol");
const USDT = artifacts.require("../contracts/USDT.sol");
//const TUSD = artifacts.require("../contracts/TUSD.sol");
//const PAX = artifacts.require("../contracts/PAX.sol");
const TestCoin = artifacts.require("../contracts/TestCoin.sol");
const Oracle = artifacts.require("../contracts/Oracle.sol");
const DefipieTimelock = artifacts.require("../contracts/DefipieTimelock.sol");
const DefipieToken = artifacts.require("../contracts/DefipieToken.sol");

module.exports = (deployer, network, accounts) => {
   //deploy
    deployer.deploy(Oracle).then((oracleInstance) => {
      // deployer.deploy(USDC).then(() => {
      //   oracleInstance.setPrice(USDC.address, 100000000);
      // });
      // deployer.deploy(TUSD).then(() => {
      //   oracleInstance.setPrice(TUSD.address, 100000000);
      // });
      // deployer.deploy(PAX).then(() => {
      //   oracleInstance.setPrice(PAX.address, 100000000);
      // });
      deployer.deploy(TestCoin).then((instance) => {
        oracleInstance.setPrice(TestCoin.address, 350000);
        instance.mint({from: accounts[0]})
      });
      deployer.deploy(USDT).then(instance => {
        //instance.transfer(accounts[1], 10000000000, {from: accounts[0]});
        oracleInstance.setPrice(USDT.address, 100000000);
      });

    	return deployer.deploy(PeerToPeerLending, Oracle.address);
    });
    
    deployer.deploy(DefipieToken).then(() => {
      return deployer.deploy(DefipieTimelock, DefipieToken.address);
    });
};