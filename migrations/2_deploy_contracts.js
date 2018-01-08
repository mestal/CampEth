var MainContract = artifacts.require("MainContract");
var CampEth = artifacts.require("CampEth");

module.exports = function(deployer) {
  deployer.deploy(MainContract);
  deployer.deploy(CampEth, "IPhoneCode00001", "IPhone", 2, 100, ["ABC01","ABC02"]);
  deployer.deploy(CampEth, "IPhoneCode00002", "IPhone", 2, 100, ["DEF01","DEF02"]);
  deployer.deploy(CampEth, "Samsung00001", "Samsung", 2, 100, ["XYZ01","XYZ02"]);
};