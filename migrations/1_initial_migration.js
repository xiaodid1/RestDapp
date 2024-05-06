const Migrations = artifacts.require("RestaurantdApp.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
