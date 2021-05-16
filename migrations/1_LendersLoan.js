const Migrations = artifacts.require("LendersLoan");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
