const LendersFactory = artifacts.require("LendersFactory")
const config = require("../config.json")
const { deployProxy } = require("@openzeppelin/truffle-upgrades")
const UNERC20 = artifacts.require("UNERC20")
const ProxyContract = artifacts.require("ERC1967Proxy")
const DataProvider = artifacts.require("DataProvider")
const InterestProvider = artifacts.require("InterestRateStatergy")
const { targetERC20, name, symbol, admin } = config

module.exports = async function (deployer) {
  deployer.deploy(UNERC20, targetERC20, name, symbol, admin).then((result) => {
    return deployer
      .deploy(ProxyContract, result.address, "0x")
      .then((proxy) => {
        return deployer.deploy(DataProvider).then((dp) => {
          return deployer.deploy(InterestProvider).then((it) => {
            return deployer
              .deploy(
                LendersFactory,
                proxy.address,
                result.address,
                dp.address,
                it.address
              )
              .then((res) => console.log(res.address))
          })
        })
      })
  })
}
