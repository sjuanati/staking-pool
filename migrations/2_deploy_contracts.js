const StakingPool = artifacts.require("StakingPool");

module.exports = (deployer, network, accounts) => {
	deployer.deploy(StakingPool, network);
};
