const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { expect, assert } = require("chai");
const Dai = artifacts.require("Dai");
const Wrapper = artifacts.require("ERC20Wrapper");

chai.use(chaiAsPromised);

contract("ERC20 token", (accounts) => {
  let dai;
  let erc20;
  let timestamp;

  describe("Contract deployment", async () => {
    before(async () => {
      dai = await Dai.new(10000, { from: accounts[1] });
      erc20 = await Wrapper.new({
        from: accounts[0],
      });
      erc20.initialize(dai.address, "Dai", "dai", accounts[0]);
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

      const borrower = await erc20.getBorrowerDetails(accounts[2]);
      assert.equal(borrower.amount, 1000);

      const usedLiq = await erc20.getUsedLiquidity();
      assert.equal(usedLiq.toNumber(), 1000);
    });

    it("account 2 payback 300 dai of loans", async () => {
      await erc20.paybackLoan(300, { from: accounts[2] });
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
      assert.equal(borrower.amount, 700);
      assert.isTrue(borrower.time < timestamp);

      await erc20.balanceSupply({ from: accounts[4] });

      borrower = await erc20.getBorrowerDetails(accounts[2]);
      assert.equal(borrower.amount, 0);

      const balance = await erc20.balanceOf(accounts[4]);
      assert(balance, 700);
    });
  });
});
