/* global BigInt */
const lock = artifacts.require("DefipieTimelock");
const pie = artifacts.require("DefipieToken");

contract("DefipieTimelock", async accounts => {
	it("create simple lock", async () => {
		let lockInstance = await lock.deployed();
		let pieInstance = await pie.deployed();

		// ---- deposit
		let balanceAccount0Before = await pieInstance.balanceOf(accounts[0]);

		await pieInstance.approve(lockInstance.address, web3.utils.toWei('100000'), {from: accounts[0]});
		await lockInstance.deposit(accounts[1], Math.round(new Date().getTime()/1000), web3.utils.toWei('100000'), 0, {from:accounts[0]});

		let balanceAccount0After = await pieInstance.balanceOf(accounts[0]);
		let balanceLockAfter = await pieInstance.balanceOf(lockInstance.address);	

		assert.equal(balanceLockAfter.toString(), web3.utils.toWei('100000'));
		assert.equal(BigInt(balanceAccount0Before) - BigInt(balanceAccount0After), BigInt(web3.utils.toWei('100000')));

		// ---- withdraw
		await lockInstance.withdraw(0, {from: accounts[5]});

		let balanceAccount1After = await pieInstance.balanceOf(accounts[1]);
		balanceLockAfter = await pieInstance.balanceOf(lockInstance.address);
		let boxes = await lockInstance.getAllBoxes();

		assert.equal(balanceLockAfter.valueOf(), 0);
		assert.equal(balanceAccount1After.toString(), web3.utils.toWei('100000'));
		assert.equal(boxes[0].totalAmount, 0);
	});

	it("create monthly lock", async () => {
		let lockInstance = await lock.deployed();
		let pieInstance = await pie.deployed();

		// ---- deposit
		let balanceAccount0Before = await pieInstance.balanceOf(accounts[0]);

		await pieInstance.approve(lockInstance.address, web3.utils.toWei('250000'), {from: accounts[0]});
		await lockInstance.deposit(accounts[2], 0, web3.utils.toWei('250000'), web3.utils.toWei('100000'), {from:accounts[0]});

		let balanceAccount0After = await pieInstance.balanceOf(accounts[0]);
		let balanceLockAfter = await pieInstance.balanceOf(lockInstance.address);	
		let boxes = await lockInstance.getAllBoxes();		

		assert.equal(balanceLockAfter.toString(), web3.utils.toWei('250000'));
		assert.equal(BigInt(balanceAccount0Before) - BigInt(balanceAccount0After), BigInt(web3.utils.toWei('250000')));
		assert.equal(boxes[1].totalAmount, web3.utils.toWei('250000'));
		assert.equal(boxes[1].monthlyAmount, web3.utils.toWei('100000'));
		assert.equal(boxes[1].releaseTime, 0);

		// ---- withdraw 1
		await lockInstance.withdraw(1, {from: accounts[5]});

		let balanceAccount2After = await pieInstance.balanceOf(accounts[2]);
		balanceLockAfter = await pieInstance.balanceOf(lockInstance.address);
		boxes = await lockInstance.getAllBoxes();		

		assert.equal(balanceLockAfter.toString(), web3.utils.toWei('150000'));
		assert.equal(balanceAccount2After.toString(), web3.utils.toWei('100000'));
		assert.equal(boxes[1].totalAmount, web3.utils.toWei('150000'));
		assert.equal(boxes[1].releaseTime, 1*30*24*60*60);

		// ---- withdraw 2
		await lockInstance.withdraw(1, {from: accounts[5]});

		balanceAccount2After = await pieInstance.balanceOf(accounts[2]);
		balanceLockAfter = await pieInstance.balanceOf(lockInstance.address);
		boxes = await lockInstance.getAllBoxes();		

		assert.equal(balanceLockAfter.toString(), web3.utils.toWei('50000'));
		assert.equal(balanceAccount2After.toString(), web3.utils.toWei('200000'));
		assert.equal(boxes[1].totalAmount, web3.utils.toWei('50000'));
		assert.equal(boxes[1].releaseTime, 2*30*24*60*60);

		// ---- withdraw 3
		await lockInstance.withdraw(1, {from: accounts[5]});

		balanceAccount2After = await pieInstance.balanceOf(accounts[2]);
		balanceLockAfter = await pieInstance.balanceOf(lockInstance.address);
		boxes = await lockInstance.getAllBoxes();		

		assert.equal(balanceLockAfter, 0);
		assert.equal(balanceAccount2After.toString(), web3.utils.toWei('250000'));
		assert.equal(boxes[1].totalAmount, 0);
		assert.equal(boxes[1].releaseTime, 3*30*24*60*60);
	});
});

