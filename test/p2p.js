/* global BigInt */
const p2p = artifacts.require("PeerToPeerLending");
const usdt = artifacts.require("USDT");
const testcoin = artifacts.require("TestCoin1");
const credit = artifacts.require("Credit");

contract("PeerToPeerLending", async accounts => {
  it("create borrow request (700 usdt => 100k testcoint) and after lend", async () => {
    let p2pInstance = await p2p.deployed();
    let usdtInstance = await usdt.deployed();
    let testcoinInstance = await testcoin.deployed();

    // ---- Create borrow request
    await usdtInstance.mint({from: accounts[1]});
    
    let beforeBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);

    await usdtInstance.approve(p2pInstance.address, 700000000, {from: accounts[1]});
    await p2pInstance.createBorrowRequest(testcoinInstance.address, web3.utils.toWei('100000'), web3.utils.toWei('10000'), 1601510400, usdtInstance.address, 700000000, {from:accounts[1]});

    let account1BorrowRequests = await p2pInstance.getUserBorrowRequests({from:accounts[1]})
    let balanceBorrowRequest = await usdtInstance.balanceOf(account1BorrowRequests[0]);
    let afterBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);

    assert.equal(balanceBorrowRequest.valueOf(), 700000000);
    assert.equal(beforeBalanceAccount1.valueOf() - afterBalanceAccount1.valueOf(), 700000000);

    // ---- lendToBorrowRequest
    let beforeBalanceAccount0 = await testcoinInstance.balanceOf(accounts[0]);

    await testcoinInstance.approve(account1BorrowRequests[0], web3.utils.toWei('100000'), {from: accounts[0]});
    await p2pInstance.lendToBorrowRequest(account1BorrowRequests[0], {from: accounts[0]});

    let testcoinBalanceBorrowRequest = await testcoinInstance.balanceOf(account1BorrowRequests[0]);
    let afterBalanceAccount0 = await testcoinInstance.balanceOf(accounts[0]);

    assert.equal(testcoinBalanceBorrowRequest.toString(), web3.utils.toWei('100000'));
    assert.equal((BigInt(beforeBalanceAccount0.valueOf()) - BigInt(afterBalanceAccount0.valueOf())).toString(), web3.utils.toWei('100000'));

    // ---- withdrawCreditAsset
    let creditInstance = await credit.at(account1BorrowRequests[0]);
    let beforeTestcoinBalanceAccount1 = await testcoinInstance.balanceOf(accounts[1]);

    await creditInstance.withdrawCreditAsset({from:accounts[1]});

		let afterTestcoinBalanceAccount1 = await testcoinInstance.balanceOf(accounts[1]);
		testcoinBalanceBorrowRequest = await testcoinInstance.balanceOf(account1BorrowRequests[0]);

		assert.equal(testcoinBalanceBorrowRequest.valueOf(), 0);
		assert.equal((BigInt(afterTestcoinBalanceAccount1.valueOf()) - BigInt(beforeTestcoinBalanceAccount1.valueOf())).toString(), web3.utils.toWei('100000'));

		// ---- repay
		let beforeUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);

		await testcoinInstance.mint({from: accounts[0]});
    await testcoinInstance.transfer(accounts[1], web3.utils.toWei('10000'), {from:accounts[0]});
		await testcoinInstance.approve(account1BorrowRequests[0], web3.utils.toWei('110000'), {from: accounts[1]});
		await creditInstance.repay({from: accounts[1]});

		let testcoinBalanceAccount1 = await testcoinInstance.balanceOf(accounts[1]);
		let afterUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);
		testcoinBalanceBorrowRequest = await testcoinInstance.balanceOf(account1BorrowRequests[0]);

		assert.equal(testcoinBalanceAccount1.valueOf(), 0);
		assert.equal(testcoinBalanceBorrowRequest.valueOf(), web3.utils.toWei('110000'));
		assert.equal(BigInt(afterUsdtBalanceAccount1.valueOf()) - BigInt(beforeUsdtBalanceAccount1.valueOf()), 700000000);

		// ---- returnInterest
		let beforeTestcoinBalanceAccount0 = await testcoinInstance.balanceOf(accounts[0]);
		
		await creditInstance.returnInterest({from:accounts[0]});

		let afterTestcoinBalanceAccount0 = await testcoinInstance.balanceOf(accounts[0]);

		assert.equal((BigInt(afterTestcoinBalanceAccount0.valueOf()) - BigInt(beforeTestcoinBalanceAccount0.valueOf())).toString(), web3.utils.toWei('110000'));
  });

  it("create lend offer (100k testcoint => 700 usdt) and after borrow", async () => {
  	let p2pInstance = await p2p.deployed();
    let usdtInstance = await usdt.deployed();
    let testcoinInstance = await testcoin.deployed();

    // ---- createLendOffer
    let beforeTestcoinBalanceAccount0 = await testcoinInstance.balanceOf(accounts[0]);

    await testcoinInstance.approve(p2pInstance.address, web3.utils.toWei('100000'), {from: accounts[0]});
    await p2pInstance.createLendOffer(testcoinInstance.address, web3.utils.toWei('100000'), web3.utils.toWei('10000'), 1601510400, {from:accounts[0]});

    let afterTestcoinBalanceAccount0 = await testcoinInstance.balanceOf(accounts[0]);
    let account0lendOffers = await p2pInstance.getUserLendOffers({from:accounts[0]});
    let balanceLendOffer = await testcoinInstance.balanceOf(account0lendOffers[0]);

    assert.equal(balanceLendOffer.toString(), web3.utils.toWei('100000'));
    assert.equal((BigInt(beforeTestcoinBalanceAccount0) - BigInt(afterTestcoinBalanceAccount0)).toString(), web3.utils.toWei('100000'));

    // ---- borrowToLendOffer
    let beforeUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);
    let beforeTestcoinBalanceAccount1 = await testcoinInstance.balanceOf(accounts[1]);

    await usdtInstance.approve(account0lendOffers[0], 700000000, {from: accounts[1]});
    await p2pInstance.borrowToLendOffer(account0lendOffers[0], usdtInstance.address, 700000000, {from:accounts[1]})

    let afterUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);
    let afterTestcoinBalanceAccount1 = await testcoinInstance.balanceOf(accounts[1]);
    let testcoinBalanceLendOffer = await testcoinInstance.balanceOf(account0lendOffers[0]);

    assert.equal(testcoinBalanceLendOffer.valueOf(), 0);
    assert.equal(BigInt(beforeUsdtBalanceAccount1) - BigInt(afterUsdtBalanceAccount1), BigInt(700000000));
    assert.equal((BigInt(afterTestcoinBalanceAccount1) - BigInt(beforeTestcoinBalanceAccount1)).toString(), web3.utils.toWei('100000'));

    // ---- repay
    let creditInstance = await credit.at(account0lendOffers[0]);
		beforeUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);

		await testcoinInstance.transfer(accounts[1], web3.utils.toWei('10000'), {from:accounts[0]});
		await testcoinInstance.approve(account0lendOffers[0], web3.utils.toWei('110000'), {from: accounts[1]});
		await creditInstance.repay({from: accounts[1]});

		let testcoinBalanceAccount1 = await testcoinInstance.balanceOf(accounts[1]);
		afterUsdtBalanceAccount1 = await usdtInstance.balanceOf(accounts[1]);
		testcoinBalanceLendOffer = await testcoinInstance.balanceOf(account0lendOffers[0]);

		assert.equal(testcoinBalanceAccount1.valueOf(), 0);
		assert.equal(testcoinBalanceLendOffer.toString(), web3.utils.toWei('110000'));
		assert.equal(BigInt(afterUsdtBalanceAccount1) - BigInt(beforeUsdtBalanceAccount1), BigInt(700000000));

		// ---- returnInterest
		beforeTestcoinBalanceAccount0 = await testcoinInstance.balanceOf(accounts[0]);
		
		await creditInstance.returnInterest({from:accounts[0]});

		afterTestcoinBalanceAccount0 = await testcoinInstance.balanceOf(accounts[0]);

		assert.equal((BigInt(afterTestcoinBalanceAccount0) - BigInt(beforeTestcoinBalanceAccount0)).toString(), web3.utils.toWei('110000'));
  });


});