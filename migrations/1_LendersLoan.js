const Migrations = artifacts.require("LendersFactory")
const config = require("../config.json")
const { deployProxy } = require("@openzeppelin/truffle-upgrades")
const Wrapper = artifacts.require("UNERC20")
const { targetERC20, name, symbol, admin } = config

module.exports = async function (deployer) {
  const instance = await deployProxy(Wrapper, [
    targetERC20,
    name,
    symbol,
    admin,
  ])

  deployer.deploy(Migrations, instance.address)
}
