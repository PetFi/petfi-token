const PFToken = artifacts.require("PFToken");

module.exports = function (deployer) {
  deployer.deploy(PFToken);
};
