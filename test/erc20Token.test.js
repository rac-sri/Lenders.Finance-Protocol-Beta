const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { expect, assert } = require("chai");
const Dai = artifacts.require("Dai");
const Wrapper = artifacts.require("UNERC20");
const SmartContract = artifacts.require("Store");
const exceptions = require("./exceptions");

chai.use(chaiAsPromised);

contract("ERC20 token", (accounts) => {
  let dai;
  let erc20;
  let timestamp;
  let store;

  describe("Contract deployment", async () => {
    before(async () => {
      dai = await Dai.new(10000, { from: accounts[1] });
      erc20 = await Wrapper.new({
        from: accounts[0],
      });
      erc20.initialize(dai.address, "Dai", "dai", accounts[0]);
      store = await SmartContract.new();
    });

    it("account 0 should have MULTISIG role", async () => {
      const hash = await erc20.MULTISIGADMIN();
      const role = await erc20.hasRole(hash, accounts[0]);
      assert.equal(role, true);
    });
    it("account 1 sends some dai to the wrapper token", async () => {
      await dai.transfer(erc20.address, 5000, { from: accounts[1] });
      const balanceLeft = await dai.balanceOf(accounts[1]);
      assert.equal(balanceLeft, 5000);
      await erc20.increaseSupply(5000, accounts[1], { from: accounts[0] });
      const supplied = await erc20.getLiquidityByAddress(accounts[1]);
      assert(supplied, 5000);
      assert.equal(await erc20.getTotalLiquidity(), 5000);
    });

    it("account 2 request for a loan of 1000 dai", async () => {
      await erc20.getLoan(accounts[2], 1, 1000);
      assert.equal(await erc20.balanceOf(accounts[2]), 1000);

      const usedLiq = await erc20.getUsedLiquidity();
      assert.equal(usedLiq.toNumber(), 1000);
    });

    it("account 2 payback 300 dai of loans", async () => {
      await erc20.paybackLoan(300, accounts[2], { from: accounts[0] });
      const balance = await erc20.balanceOf(accounts[2]);
      assert.equal(balance, 700);
      const availaibleLiquidity = await erc20.getAvailaibleSupply();
      assert.equal(availaibleLiquidity, 4300);
    });

    it("timestamp increased by 1 day", async () => {
      let id = 0;
      const oldBlockNUmber = await web3.eth.getBlockNumber();
      const { timestamp: oldTimeStamp } = await web3.eth.getBlock(
        oldBlockNUmber
      );
      await web3.currentProvider.send(
        {
          jsonrpc: "2.0",
          method: "evm_increaseTime",
          params: [90000],
          id,
        },
        () => {}
      ); // > 86400 for 1 day

      await web3.currentProvider.send(
        {
          jsonrpc: "2.0",
          method: "evm_mine",
          id: id + 1,
        },
        () => {}
      );

      const newBlockNumber = await web3.eth.getBlockNumber();
      const { timestamp: newTimestamp } = await web3.eth.getBlock(
        newBlockNumber
      );
      assert.isTrue(newTimestamp - oldTimeStamp > 86400);
      timestamp = newTimestamp;
    });

    it("balanceSupply() function after 1 day time", async () => {
      let borrower = await erc20.getBorrowerDetails(accounts[2]);
      assert.isTrue(borrower[0].toNumber() < timestamp);

      await erc20.balanceSupply({ from: accounts[0] });

      assert.equal(await erc20.balanceOf(accounts[2]), 0);
    });

    it("transfer() function", async () => {
      await erc20.getLoan(accounts[5], 1, 1000);
      assert.equal(await erc20.balanceOf(accounts[5]), 1000);

      await erc20.transfer(store.address, 600, { from: accounts[5] });
      assert.equal(await erc20.balanceOf(store.address), 600);
      assert.equal(await erc20.balanceOf(accounts[5]), 400);
    });

    it("transferFrom() function", async () => {
      await erc20.getLoan(accounts[6], 1, 1000);
      assert.equal(await erc20.balanceOf(accounts[6]), 1000);

      await erc20.approve(accounts[7], 500, { from: accounts[6] });
      await erc20.transferFrom(accounts[6], store.address, 500, {
        from: accounts[7],
      });

      assert.equal(await erc20.balanceOf(store.address), 1100);
      assert.equal(await erc20.balanceOf(accounts[6]), 500);
    });

    it("transfer() should not work for account[5] as it has already issued loan", async () => {
      await exceptions.LiquidityAlreadyTaken(
        erc20.getLoan(accounts[5], 1, 1000)
      );
    });

    it(".decreaseSupply()", async () => {
      await erc20.decreaseSupply(500, accounts[1], { from: accounts[0] });
      const availaibleLiquidity = await erc20.getTotalLiquidity();
      assert.equal(availaibleLiquidity, 4500);
    });
  });
});
