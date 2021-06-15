const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { expect, assert } = require("chai");
const Dai = artifacts.require("Dai");
const Factory = artifacts.require("LendersFactory");
const unERC20Proxy = artifacts.require("UnERC20Proxy");
const unERC20 = artifacts.require("UNERC20");

chai.use(chaiAsPromised);

contract("Factory Contract", (accounts) => {
  let dai;
  let factory;
  let unERC20ProxyContract;
  let urERC20contract;

  describe("create new liquidity contract and provide liquidity", async () => {
    before(async () => {
      dai = await Dai.new(10000, { from: accounts[0] });
      unERC20ProxyContract = await unERC20Proxy.new(
        dai.address,
        web3.utils.asciiToHex(""),
        {
          from: accounts[0],
        }
      );

      console.log(
        "implementaion",
        await unERC20ProxyContract.getImplementation()
      );
      urERC20contract = await unERC20.new();
      await urERC20contract.initialize(dai.address, "Dai", "Dai", accounts[0]);
      // await unERC20ProxyContract.upgradeTo(urERC20contract.address, {
      //   from: accounts[0],
      // });
      factory = await Factory.new(unERC20ProxyContract.address, {
        from: accounts[0],
      });
    });

    it("dsfdsf", async () => {
      await factory.createLiquidityContract();
    });
  });
});
