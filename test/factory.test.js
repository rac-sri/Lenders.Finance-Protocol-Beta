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

      urERC20contract = await unERC20.new();

      await urERC20contract.initialize(dai.address, "Dai", "Dai", accounts[0]);

      unERC20ProxyContract = await unERC20Proxy.new(
        urERC20contract.address,
        "0x",
        {
          from: accounts[0],
        }
      );

      factory = await Factory.new(
        unERC20ProxyContract.address,
        urERC20contract.address,
        {
          from: accounts[0],
        }
      );
    });

    it("implementation contract is correct", async () => {
      assert.equal(
        urERC20contract.address,
        await unERC20ProxyContract.getImplementation()
      );
    });
  });

  describe("Liquidity Contract", async () => {
    let daiTokenWrapper;
    let daiImplementationAddress;

    it("create a new token wrapper contract", async () => {
      await factory.createLiquidityContract(dai.address, "Dai", "Dai");

      const daiAddress = await factory.returnProxyContract(dai.address);

      const unerc20implementation = new web3.eth.Contract(
        unERC20Proxy.abi,
        daiAddress
      );

      daiImplementationAddress = await unerc20implementation.methods
        .getImplementation()
        .call();

      daiTokenWrapper = new web3.eth.Contract(
        unERC20.abi,
        daiImplementationAddress
      );

      assert.equal(await daiTokenWrapper.methods.name().call(), "Dai");
    });

    it("adding liquidity", async () => {
      // approve dai spending
      await dai.approve(factory.address, 5000);
      assert.equal(await dai.allowance(accounts[0], factory.address), 5000);

      await factory.addLiquidity(4000, dai.address);
      assert.equal(await dai.balanceOf(daiImplementationAddress), 4000);

      assert.equal(
        await daiTokenWrapper.methods.getTotalLiquidity().call(),
        4000
      );
    });

    it("account[2] issues a loan", async () => {});
  });
});
