const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const Dai = artifacts.require("DAI");
const Wrapper = artifacts.require("ERC20Wrapper");
const Wrapper2 = artifacts.require("ERC20Wrapper");

describe("upgrade", () => {
  it("works", async () => {
    const dai = await Dai.deployed();
    const w1 = await deployProxy(Wrapper, [
      dai.address,
      "Dai",
      "DAI",
      accounts[0],
    ]);
    const w2 = await upgradeProxy(w1.address, Wrapper2);

    const value = await w2.coin;
    assert.equal(value.toString(), dai.address);
  });
});
