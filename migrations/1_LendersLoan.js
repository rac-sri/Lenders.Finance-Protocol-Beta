const Migrations = artifacts.require("LendersFactory")
const config = require("../config.json")
const { deployProxy } = require("@openzeppelin/truffle-upgrades")
const UNERC20 = artifacts.require("UNERC20")
const ProxyContract = artifacts.require("ERC1967Proxy")
const { targetERC20, name, symbol, admin } = config

module.exports = async function (deployer) {
  deployer
    .deploy(UNERC20, targetERC20, name, symbol, admin)
    .then(async (result) => {
      const proxy = await deployer.deploy(ProxyContract, result.address, "0x")

      deployer.deploy(Migrations, proxy.address, result.address)
    })
}
