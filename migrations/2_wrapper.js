const Migrations = artifacts.require("ERC20Wrapper");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
