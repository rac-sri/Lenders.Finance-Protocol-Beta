const LendersFactory = artifacts.require("LendersFactory")
const config = require("../config.json")
const { deployProxy } = require("@openzeppelin/truffle-upgrades")
const UNERC20 = artifacts.require("UNERC20")
const ProxyContract = artifacts.require("ERC1967Proxy")
const DataProvider = artifacts.require("DataProvider")
const InterestProvider = artifacts.require("InterestRateStatergy")
const ERC20 = artifacts.require("Dai")

// , dai.address, "Dai", "dai", admin

module.exports = async function (deployer) {
  deployer.deploy(ERC20, 10000).then(async (dai) => {
    return deployer.deploy(UNERC20).then((result) => {
      return deployer
        .deploy(ProxyContract, result.address, "0x")
        .then((proxy) => {
          return deployer.deploy(DataProvider).then((dp) => {
            return deployer.deploy(InterestProvider).then(async (it) => {
              const itInstance = await InterestProvider.deployed()
              await itInstance.initialize(dp.address, 5)
              return deployer
                .deploy(
                  LendersFactory,
                  proxy.address,
                  result.address,
                  dp.address,
                  it.address
                )
                .then(async (res) => {
                  const DataProviderInstance = await DataProvider.deployed()
                  await DataProviderInstance.initialize(10, 5, res.address)
                })
            })
          })
        })
    })
  })
}
