const PeerToPeerLending = artifacts.require("../contracts/PeerToPeerLending.sol");
const USDC = artifacts.require("../contracts/USDC.sol");
const USDT = artifacts.require("../contracts/USDT.sol");
const TUSD = artifacts.require("../contracts/TUSD.sol");
const PAX = artifacts.require("../contracts/PAX.sol");
const TestCoin1 = artifacts.require("../contracts/TestCoin1.sol");
const TestCoin2 = artifacts.require("../contracts/TestCoin2.sol");
const TestCoin3 = artifacts.require("../contracts/TestCoin3.sol");
const Oracle = artifacts.require("../contracts/Oracle.sol");
const SimpleOracle = artifacts.require("../contracts/SimpleOracle.sol");
const LinkOracle = artifacts.require("../contracts/LinkOracle.sol");
// const DefipieTimelock = artifacts.require("../contracts/DefipieTimelock.sol");
// const DefipieToken = artifacts.require("../contracts/DefipieToken.sol");

module.exports = (deployer, network, accounts) => {
  deployer.then(async () => {
    let oracleInstance = await deployer.deploy(Oracle);
    let simpleOracleInstance = await deployer.deploy(SimpleOracle);

    await deployer.deploy(USDT);
    await deployer.deploy(USDC);
    await deployer.deploy(TUSD);
    await deployer.deploy(PAX);
    await deployer.deploy(TestCoin1);
    await deployer.deploy(TestCoin2);
    await deployer.deploy(TestCoin3);

    simpleOracleInstance.setPrice(USDT.address, 100000000);
    simpleOracleInstance.setPrice(USDC.address, 100000000);
    simpleOracleInstance.setPrice(TUSD.address, 100000000);
    simpleOracleInstance.setPrice(PAX.address, 100000000);
    simpleOracleInstance.setPrice(TestCoin1.address, 350000);
    simpleOracleInstance.setPrice(TestCoin2.address, 350000);
    simpleOracleInstance.setPrice(TestCoin3.address, 350000);

    oracleInstance.setOracle(USDT.address, SimpleOracle.address);
    oracleInstance.setOracle(USDC.address, SimpleOracle.address);
    oracleInstance.setOracle(TUSD.address, SimpleOracle.address);
    oracleInstance.setOracle(PAX.address, SimpleOracle.address);
    oracleInstance.setOracle(TestCoin1.address, SimpleOracle.address);
    oracleInstance.setOracle(TestCoin2.address, SimpleOracle.address);
    oracleInstance.setOracle(TestCoin3.address, SimpleOracle.address);

    deployer.deploy(PeerToPeerLending, Oracle.address);

    let linkOracleInstance = await deployer.deploy(LinkOracle);
    const linkAddress = '0x20fe562d797a42dcb3399062ae9546cd06f63280';
    linkOracleInstance.setFeed(linkAddress, '0xc21c178fE75aAd2017DA25071c54462e26d8face');
    oracleInstance.setOracle(linkAddress, LinkOracle.address);
  });
  
  
  // deployer.deploy(DefipieToken).then(() => {
  //   return deployer.deploy(DefipieTimelock, DefipieToken.address);
  // });
};