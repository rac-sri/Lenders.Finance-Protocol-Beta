const { deployProxy } = require("@openzeppelin/truffle-upgrades")
const Wrapper = artifacts.require("ERC20Wrapper")
const { targetERC20, name, symbol, admin } = process.env.TOKENADDRESS

module.exports = async function (deployer) {
  const instance = await deployProxy(Wrapper, [
    targetERC20,
    name,
    symbol,
    admin,
  ])
  console.log("deployed", instance.address)
}
