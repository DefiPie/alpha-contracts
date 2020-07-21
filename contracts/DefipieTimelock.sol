// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/SafeERC20.sol";

contract DefipieTimelock {
  using SafeERC20 for IERC20;

  // ERC20 basic token contract being held
  IERC20 private _token;

  struct LockBox {
    address beneficiary;
    uint amount;
    uint releaseTime;
  }

  LockBox[] public lockBox; // This could be a mapping by address, but these numbered lockBoxes support possibility of multiple tranches per address

  event LogLockBoxDeposit(address sender, uint amount, uint releaseTime);   
  event LogLockBoxWithdrawal(address receiver, uint amount);

  constructor(address tokenContract) public {
    _token = IERC20(tokenContract);
  }

  /**
   * @return the token being held.
   */
  function token() public view returns (IERC20) {
    return _token;
  }

  function deposit(address beneficiary, uint amount, uint releaseTime) public returns(bool success) {
    require(token.transferFrom(msg.sender, address(this), amount));
    LockBox memory l;
    l.beneficiary = beneficiary;
    l.amount = amount;
    l.releaseTime = releaseTime;
    lockBox.push(l);
    emit LogLockBoxDeposit(msg.sender, amount, releaseTime);
    return true;
  }

  function withdraw(uint lockBoxNumber) public returns(bool success) {
    LockBox storage l = lockBox[lockBoxNumber];
    require(l.beneficiary == msg.sender);
    require(l.releaseTime <= now);
    require(l.amount > 0);
    uint amount = l.amount;
    l.amount = 0;
    emit LogLockBoxWithdrawal(msg.sender, amount);
    require(token.transfer(msg.sender, amount));
    return true;
  }    

}