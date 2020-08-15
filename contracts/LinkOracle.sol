pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorInterface.sol";

contract LinkOracle is Ownable {
	// asset => feed
	mapping(address => address) public feeds;

	function getPrice(address asset) public view returns(int) {
		return AggregatorInterface(feeds[asset]).latestAnswer();		
	}

	function setFeed(address asset, address feed) public onlyOwner returns(bool) {
		feeds[asset] = feed;
		return true;
	}
}