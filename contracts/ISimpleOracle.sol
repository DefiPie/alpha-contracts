pragma solidity ^0.6.0;

import './IOracle.sol';

interface ISimpleOracle is IOracle {
	function setPrice(address asset, uint price) external returns(bool);
}