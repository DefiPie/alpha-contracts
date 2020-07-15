const BorrowRequest = artifacts.require("../contracts/BorrowRequest.sol");
const LendOffer = artifacts.require("../contracts/LendOffer.sol");
const PeerToPeerLending = artifacts.require("../contracts/PeerToPeerLending.sol");
const USDC = artifacts.require("../contracts/USDC.sol");
const USDT = artifacts.require("../contracts/USDT.sol");
const TUSD = artifacts.require("../contracts/TUSD.sol");
const PAX = artifacts.require("../contracts/PAX.sol");
const ShitCoin = artifacts.require("../contracts/ShitCoin.sol");

module.exports = (deployer) => {
   //deploy
    deployer.deploy(PeerToPeerLending);
    deployer.deploy(USDC);
    deployer.deploy(USDT);
    deployer.deploy(TUSD);
    deployer.deploy(PAX);
    deployer.deploy(ShitCoin);
};