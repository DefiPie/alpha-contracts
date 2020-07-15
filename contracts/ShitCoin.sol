pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ShitCoin is ERC20 {
    constructor() public ERC20("Shit Coin", "SHTC") {        
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
}