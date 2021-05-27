const Migrations = artifacts.require("LendersFactory")

module.exports = function (deployer) {
  deployer.deploy(Migrations)
}
