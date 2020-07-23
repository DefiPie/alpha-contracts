pragma solidity ^0.6.0;

interface IOracle {
	function setPrice(address asset, uint price) external returns(bool);

	function getPrice(address asset) external view returns (uint);
}