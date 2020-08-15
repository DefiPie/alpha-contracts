pragma solidity ^0.6.0;

interface IOracle {
	function getPrice(address asset) external view returns (uint);
}