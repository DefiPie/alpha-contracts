pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Oracle is Ownable {

	uint decimals = 8;

	mapping(address => uint) public prices;

	function setPrice(address asset, uint price) public onlyOwner {
		prices[asset] = price;
	}

	function getPrice(address asset) public view returns (uint) {
		return prices[asset];
	}
}