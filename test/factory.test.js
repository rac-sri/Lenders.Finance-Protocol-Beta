const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { expect, assert } = require("chai");
const Dai = artifacts.require("Dai");
const Factory = artifacts.require("LendersFactory");
const unERC20Proxy = artifacts.require("UnERC20Proxy");
const unERC20 = artifacts.require("UNERC20");
const DataProvider = artifacts.require("DataProvider");
const InterestRate = artifacts.require("InterestRateStatergy");

chai.use(chaiAsPromised);

contract("Factory Contract", (accounts) => {
  let dai;
  let factory;
  let unERC20ProxyContract;
  let urERC20contract;
  let interestRate;
  let dataProvider;

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

      interestRate = await InterestRate.new();

      dataProvider = await DataProvider.new();

      await dataProvider.initialize(10, 5);

      await interestRate.initialize(dataProvider.address, 5);

      factory = await Factory.new(
        unERC20ProxyContract.address,
        urERC20contract.address,
        dataProvider.address,
        interestRate.address,
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
    let daiAddress;

    it("create a new token wrapper contract", async () => {
      await factory.createLiquidityContract(dai.address, "Dai", "Dai");

      daiAddress = await factory.returnProxyContract(dai.address);

      daiTokenWrapper = new web3.eth.Contract(unERC20.abi, daiAddress);
      const name = await daiTokenWrapper.methods.name().call();
      assert.equal(name, "Dai");
    });

    it("adding liquidity", async () => {
      // approve dai spending
      await dai.approve(factory.address, 5000);
      assert.equal(await dai.allowance(accounts[0], factory.address), 5000);

      await factory.addLiquidity(4000, dai.address);
      assert.equal(await dai.balanceOf(daiAddress), 4000);

      assert.equal(
        await daiTokenWrapper.methods.getTotalLiquidity().call(),
        4000
      );
    });

    // it("Interest Calculation Functions Working", async () => {
    //   const dataInput = await dataProvider.getValuesForInterestCalculation(
    //     daiTokenWrapper._address
    //   );

    //   assert.equal(dataInput[0], 10);
    //   assert.equal(dataInput[1], 5);
    //   assert.equal(dataInput[2], 0);
    //   assert.equal(dataInput[3].toNumber(), 4000);
    //   const data = await interestRate.calculatePaymentAmount(
    //     unERC20ProxyContract.address,
    //     1500,
    //     1
    //   );
    //   console.log(data[0].toNumber(), data[1].toNumber());
    //   assert.equal(data[1], 75);
    // });

    it("account[2] issues a loan", async () => {
      await dai.transfer(accounts[2], 2000);

      assert.equal(await dai.balanceOf(accounts[2]), 2000);

      await factory.payInterest(1500, { value: 15, from: accounts[2] });

      await factory.issueLoan(dai.address, 1, 1500, { from: accounts[2] });

      assert.equal(
        await daiTokenWrapper.methods.balanceOf(accounts[2]).call(),
        1500
      );
    });

    it("accounts[2] paybacks the loan", async () => {
      await factory.paybackLoan(dai.address, 1000, { from: accounts[2] });

      assert.equal(
        await daiTokenWrapper.methods.balanceOf(accounts[2]).call(),
        500
      );
    });

    // balanceSupply Test
    it("balanceSupply() test", async () => {
      assert(await factory.balanceSupply.call(dai.address), 500);
    });
    // transfer events test
  });
});
