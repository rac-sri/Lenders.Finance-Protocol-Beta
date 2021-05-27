const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { expect, assert } = require("chai");
const Dai = artifacts.require("Dai");
const Wrapper = artifacts.require("ERC20Wrapper");

chai.use(chaiAsPromised);

contract("ERC20 token", (accounts) => {
  let dai;
  let erc20;

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
      assert(usedLiq, 1000);
    });

    it("account 2 payback 300 dai of loans", async () => {
      await erc20.paybackLoan(300, { from: accounts[2] });
      const balance = await erc20.balanceOf(accounts[2]);
      assert.equal(balance, 700);
      // const availaibleLiquidity = await erc20.getAvailaibleSupply();
      // assert.equal(availaibleLiquidity, 4300);
    });
  });
});
