const config = require("../config.json")
const { deployProxy } = require("@openzeppelin/truffle-upgrades")
const Wrapper = artifacts.require("Dai")

module.exports = async function (deployer) {
  deployer.deploy(Wrapper, 10000)
}
