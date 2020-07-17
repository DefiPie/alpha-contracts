const BorrowRequest = artifacts.require("../contracts/BorrowRequest.sol");
const LendOffer = artifacts.require("../contracts/LendOffer.sol");
const PeerToPeerLending = artifacts.require("../contracts/PeerToPeerLending.sol");
const USDC = artifacts.require("../contracts/USDC.sol");
const USDT = artifacts.require("../contracts/USDT.sol");
const TUSD = artifacts.require("../contracts/TUSD.sol");
const PAX = artifacts.require("../contracts/PAX.sol");
const ShitCoin = artifacts.require("../contracts/ShitCoin.sol");

module.exports = (deployer, network, accounts) => {
   //deploy
    deployer.deploy(PeerToPeerLending);
    deployer.deploy(USDC);
    deployer.deploy(TUSD);
    deployer.deploy(PAX);
    deployer.deploy(ShitCoin);

    deployer.deploy(USDT).then(instance => {
	    instance.transfer(accounts[1], 10000000000, {from: accounts[0]});
	  });
};