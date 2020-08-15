pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import './IOracle.sol';

contract Oracle is IOracle, Ownable {
	// asset => oracle
	mapping(address => address) public oracles;

	function getPrice(address asset) public view override returns (uint) {
		return IOracle(oracles[asset]).getPrice(asset);
	}

	function setOracle(address asset, address oracle) public onlyOwner returns(bool) {
		oracles[asset] = oracle;
		return true;
	}
}