/* global BigInt */
const p2p = artifacts.require("PeerToPeerLending");
const usdt = artifacts.require("USDT");
const shitcoin = artifacts.require("ShitCoin");
const credit = artifacts.require("Credit");

contract("createBorrowRequest", async accounts => {
  it("create borrow request (700 usdt => 100k shitcoint) and after lend", async () => {
    let p2pInstance = await p2p.deployed();
    let usdtInstance = await usdt.deployed();
    let shitcoinInstance = await shitcoin.deployed();

    // ---- Create borrow request
    let beforeBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);

    await usdtInstance.approve(p2pInstance.address, 700000000, {from: accounts[1]});
    await p2pInstance.createBorrowRequest(shitcoinInstance.address, web3.utils.toWei('100000'), web3.utils.toWei('10000'), 1601510400, usdtInstance.address, 700000000, {from:accounts[1]});

    let account1BorrowRequests = await p2pInstance.getUserBorrowRequests({from:accounts[1]})
    let balanceBorrowRequest = await usdtInstance.balanceOf(account1BorrowRequests[0]);
    let afterBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);

    assert.equal(balanceBorrowRequest.valueOf(), 700000000);
    assert.equal(beforeBalanceAccount1.valueOf() - afterBalanceAccount1.valueOf(), 700000000);

    // ---- lendToBorrowRequest
    let beforeBalanceAccount0 = await shitcoinInstance.balanceOf(accounts[0]);

    await shitcoinInstance.approve(account1BorrowRequests[0], web3.utils.toWei('100000'), {from: accounts[0]});
    await p2pInstance.lendToBorrowRequest(account1BorrowRequests[0], {from: accounts[0]});

    let shitcoinBalanceBorrowRequest = await shitcoinInstance.balanceOf(account1BorrowRequests[0]);
    let afterBalanceAccount0 = await shitcoinInstance.balanceOf(accounts[0]);

    assert.equal(shitcoinBalanceBorrowRequest.toString(), web3.utils.toWei('100000'));
    assert.equal((BigInt(beforeBalanceAccount0.valueOf()) - BigInt(afterBalanceAccount0.valueOf())).toString(), web3.utils.toWei('100000'));

    // ---- withdrawCreditAsset
    let creditInstance = await credit.at(account1BorrowRequests[0]);
    let beforeShitcoinBalanceAccount1 = await shitcoinInstance.balanceOf(accounts[1]);

    await creditInstance.withdrawCreditAsset({from:accounts[1]});

		let afterShitcoinBalanceAccount1 = await shitcoinInstance.balanceOf(accounts[1]);
		shitcoinBalanceBorrowRequest = await shitcoinInstance.balanceOf(account1BorrowRequests[0]);

		assert.equal(shitcoinBalanceBorrowRequest.valueOf(), 0);
		assert.equal((BigInt(afterShitcoinBalanceAccount1.valueOf()) - BigInt(beforeShitcoinBalanceAccount1.valueOf())).toString(), web3.utils.toWei('100000'));

		// ---- repay
		let beforeUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);

		await shitcoinInstance.transfer(accounts[1], web3.utils.toWei('10000'), {from:accounts[0]});
		await shitcoinInstance.approve(account1BorrowRequests[0], web3.utils.toWei('110000'), {from: accounts[1]});
		await creditInstance.repay({from: accounts[1]});

		let shitcoinBalanceAccount1 = await shitcoinInstance.balanceOf(accounts[1]);
		let afterUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);
		shitcoinBalanceBorrowRequest = await shitcoinInstance.balanceOf(account1BorrowRequests[0]);

		assert.equal(shitcoinBalanceAccount1.valueOf(), 0);
		assert.equal(shitcoinBalanceBorrowRequest.valueOf(), web3.utils.toWei('110000'));
		assert.equal(BigInt(afterUsdtBalanceAccount1.valueOf()) - BigInt(beforeUsdtBalanceAccount1.valueOf()), 700000000);

		// ---- returnInterest
		let beforeShitcoinBalanceAccount0 = await shitcoinInstance.balanceOf(accounts[0]);
		
		await creditInstance.returnInterest({from:accounts[0]});

		let afterShitcoinBalanceAccount0 = await shitcoinInstance.balanceOf(accounts[0]);

		assert.equal((BigInt(afterShitcoinBalanceAccount0.valueOf()) - BigInt(beforeShitcoinBalanceAccount0.valueOf())).toString(), web3.utils.toWei('110000'));
  });

  it("create lend offer (100k shitcoint => 700 usdt) and after borrow", async () => {
  	let p2pInstance = await p2p.deployed();
    let usdtInstance = await usdt.deployed();
    let shitcoinInstance = await shitcoin.deployed();

    // ---- createLendOffer
    let beforeShitcoinBalanceAccount0 = await shitcoinInstance.balanceOf(accounts[0]);

    await shitcoinInstance.approve(p2pInstance.address, web3.utils.toWei('100000'), {from: accounts[0]});
    await p2pInstance.createLendOffer(shitcoinInstance.address, web3.utils.toWei('100000'), web3.utils.toWei('10000'), 1601510400, {from:accounts[0]});

    let afterShitcoinBalanceAccount0 = await shitcoinInstance.balanceOf(accounts[0]);
    let account0lendOffers = await p2pInstance.getUserLendOffers({from:accounts[0]});
    let balanceLendOffer = await shitcoinInstance.balanceOf(account0lendOffers[0]);

    assert.equal(balanceLendOffer.toString(), web3.utils.toWei('100000'));
    assert.equal((BigInt(beforeShitcoinBalanceAccount0) - BigInt(afterShitcoinBalanceAccount0)).toString(), web3.utils.toWei('100000'));

    // ---- borrowToLendOffer
    let beforeUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);
    let beforeShitcoinBalanceAccount1 = await shitcoinInstance.balanceOf(accounts[1]);

    await usdtInstance.approve(account0lendOffers[0], 700000000, {from: accounts[1]});
    await p2pInstance.borrowToLendOffer(account0lendOffers[0], usdtInstance.address, 700000000, {from:accounts[1]})

    let afterUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);
    let afterShitcoinBalanceAccount1 = await shitcoinInstance.balanceOf(accounts[1]);
    let shitcoinBalanceLendOffer = await shitcoinInstance.balanceOf(account0lendOffers[0]);

    assert.equal(shitcoinBalanceLendOffer.valueOf(), 0);
    assert.equal(BigInt(beforeUsdtBalanceAccount1) - BigInt(afterUsdtBalanceAccount1), BigInt(700000000));
    assert.equal((BigInt(afterShitcoinBalanceAccount1) - BigInt(beforeShitcoinBalanceAccount1)).toString(), web3.utils.toWei('100000'));

    // ---- repay
    let creditInstance = await credit.at(account0lendOffers[0]);
		beforeUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);

		await shitcoinInstance.transfer(accounts[1], web3.utils.toWei('10000'), {from:accounts[0]});
		await shitcoinInstance.approve(account0lendOffers[0], web3.utils.toWei('110000'), {from: accounts[1]});
		await creditInstance.repay({from: accounts[1]});

		let shitcoinBalanceAccount1 = await shitcoinInstance.balanceOf(accounts[1]);
		afterUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);
		shitcoinBalanceLendOffer = await shitcoinInstance.balanceOf(account0lendOffers[0]);

		assert.equal(shitcoinBalanceAccount1.valueOf(), 0);
		assert.equal(shitcoinBalanceLendOffer.toString(), web3.utils.toWei('110000'));
		assert.equal(BigInt(afterUsdtBalanceAccount1) - BigInt(beforeUsdtBalanceAccount1), BigInt(700000000));

		// ---- returnInterest
		beforeShitcoinBalanceAccount0 = await shitcoinInstance.balanceOf(accounts[0]);
		
		await creditInstance.returnInterest({from:accounts[0]});

		afterShitcoinBalanceAccount0 = await shitcoinInstance.balanceOf(accounts[0]);

		assert.equal((BigInt(afterShitcoinBalanceAccount0) - BigInt(beforeShitcoinBalanceAccount0)).toString(), web3.utils.toWei('110000'));
  });


});