const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { expect, assert } = require("chai");
const Dai = artifacts.require("Dai");
const Wrapper = artifacts.require("ERC20Wrapper");
const Wrapper2 = artifacts.require("ERC20Wrapper");

chai.use(chaiAsPromised);

contract("Wrapper", (accounts) => {
  describe("upgrade", () => {
    it("Deploy 1 contract, then migrate using proxy to another deployment", async () => {
      const dai = await Dai.new();
      const w1 = await deployProxy(Wrapper, [
        dai.address,
        "Dai",
        "DAI",
        accounts[0],
      ]);
      const w2 = await upgradeProxy(w1.address, Wrapper2);
      const state = await w2.MULTISIGADMIN();
      assert(await w2.hasRole(state, accounts[0]));
    });
  });
});
