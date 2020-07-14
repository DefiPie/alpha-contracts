const BorrowRequest = artifacts.require("../contracts/BorrowRequest.sol");
const LendOffer = artifacts.require("../contracts/LendOffer.sol");
const PeerToPeerLending = artifacts.require("../contracts/PeerToPeerLending.sol");
module.exports = (deployer) => {
   //deploy
    deployer.deploy(PeerToPeerLending);

};