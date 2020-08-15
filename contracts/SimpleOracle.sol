pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import './IOracle.sol';

contract SimpleOracle is IOracle, Ownable {

	uint decimals = 8;

	mapping(address => uint) public prices;

	function setPrice(address asset, uint price) public onlyOwner returns(bool) {
		prices[asset] = price;
		return true;
	}

	function getPrice(address asset) public view override returns (uint) {
		return prices[asset];
	}
}