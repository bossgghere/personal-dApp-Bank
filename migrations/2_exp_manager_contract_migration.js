const ExpmanagerContract = artifacts.require("ExpmanagerContract");

module.exports = function (deployer) {
  deployer.deploy(ExpmanagerContract);
};
