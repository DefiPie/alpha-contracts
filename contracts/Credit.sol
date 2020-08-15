pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './Oracle.sol';

contract Credit is Ownable {
	using SafeMath for uint;

	address lender;
	address borrower;
	address creditAsset;
	uint creditAmount;
	uint returnAmount;
	address collateralAsset;
	uint collateralAmount;
	uint createDate;
	uint returnDate;

	enum State { pendingCollateral, pendingAsset, pendingLend, pendingBorrow, repayment, interestReturns, finished }
  State state;

  enum AppType { borrowRequest, lendOffer }
  AppType appType;

  /** @dev Events
  *
  */
  event LogCreditInitialized(address indexed _address, AppType indexed _appType, uint indexed timestamp);
  event LogCreditSetCollateral(address indexed _address, uint indexed timestamp);
  event LogCreditSetAsset(address indexed _address, uint indexed timestamp);
  event LogCreditLend(address indexed _address, uint indexed timestamp);
  event LogCreditWithdrawal(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogCreditRepayment(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogCreditReturnInterest(address indexed _address, uint indexed timestamp);
  event LogCreditBorrow(address indexed _address, uint indexed timestamp);

  /** @dev Modifiers
  *
  */
  modifier onlyBorrower() {
    require(msg.sender == borrower, "Only for borrower");
    _;
  }

  modifier isPendingLend() {
    require(state == State.pendingLend, "Only for pending lends stage");
    _;
  }

  modifier isNotReturnDate() {
    require(returnDate > block.timestamp, "Return date is less than current date");
    _;
  }

  constructor(
    AppType _appType,
    address _creditAsset,
    uint _creditAmount, 
    uint interest,
    uint _returnDate
  ) public {
    require(_returnDate > block.timestamp, "Return date is less than current date");

    appType = _appType;

    creditAsset = _creditAsset;
    creditAmount = _creditAmount;
    returnDate = _returnDate;
    returnAmount = creditAmount.add(interest);
    createDate = block.timestamp;

    if (appType == AppType.borrowRequest) {
      borrower = tx.origin;
      state = State.pendingCollateral;
    } else {
      lender = tx.origin;
      state = State.pendingAsset;
    }

    emit LogCreditInitialized(tx.origin, appType, block.timestamp);
  }

  function setCollateral(address _collateralAsset, uint _collateralAmount) public onlyOwner returns(bool) {
    require(state == State.pendingCollateral, "Only for pending collateral stage");

    collateralAsset = _collateralAsset;
    collateralAmount = _collateralAmount;
    state = State.pendingLend;

    emit LogCreditSetCollateral(tx.origin, block.timestamp);

    return true;
  }

  function setAsset() public onlyOwner returns(bool) {
    require(state == State.pendingAsset, "Only for pending asset stage");

    state = State.pendingBorrow;

    emit LogCreditSetAsset(tx.origin, block.timestamp);

    return true;
  }

  function getBalance() public view returns(uint) {
    IERC20 creditToken = IERC20(creditAsset);

    return creditToken.balanceOf(address(this));
  }

  function getCreditAmount() public view returns(uint) {
    return creditAmount;
  }

  function getCreditAsset() public view returns (address) {
    return creditAsset;
  }

  function getInfo() public view returns (address, address, address, uint, address, uint, uint, uint, uint, State, AppType, uint) {
    return (
      borrower,         // 0
      lender,           // 1
      collateralAsset,  // 2
      collateralAmount, // 3
      creditAsset,      // 4
      creditAmount,     // 5
      returnAmount,     // 6
      createDate,       // 7
      returnDate,       // 8
      state,            // 9
      appType,          // 10
      getBalance()      // 11
    );
  }

  function lend() public onlyOwner isPendingLend isNotReturnDate returns (bool) {        
    uint balance = getBalance();
    
    require(balance <= creditAmount, "The balance is already more than requested");

    uint amount = creditAmount;
    uint rest = creditAmount.sub(balance);
    
    if (rest < amount) {
      amount = rest;
    }

    IERC20 creditToken = IERC20(creditAsset);

    require(creditToken.transferFrom(tx.origin, address(this), amount), "The credit asset is not transferred");

    lender = tx.origin;

    LogCreditLend(tx.origin, block.timestamp);

    return true;
  }

  function withdrawCreditAsset() public onlyBorrower isPendingLend returns (bool) {
    uint balance = getBalance();

    require(balance >= creditAmount, "Not enough funds on the balance");

    state = State.repayment;

    IERC20(creditAsset).transfer(borrower, balance);

    LogCreditWithdrawal(msg.sender, balance, block.timestamp);

    return true;
  }

  function repay() public onlyBorrower returns (bool) {
    require(state == State.repayment, "Only for repayment stage");   

    require(IERC20(creditAsset).transferFrom(msg.sender, address(this), returnAmount), "The credit asset is not transferred");

    IERC20 collateralToken = IERC20(collateralAsset);

    collateralToken.transfer(borrower, collateralAmount);

    state = State.interestReturns;

    LogCreditRepayment(msg.sender, returnAmount, block.timestamp);

    return true;
  }

  function returnInterest() public returns (bool) {
    require(state == State.interestReturns, "Only for return interest stage");
    require(msg.sender == lender, "Only for lender");

    IERC20(creditAsset).transfer(msg.sender, getBalance());

    state = State.finished;
    
    LogCreditReturnInterest(msg.sender, block.timestamp);

    return true;
  }

  function borrow(address _collateralAsset, uint _collateralAmount) public onlyOwner isNotReturnDate returns (bool) {
    require(state == State.pendingBorrow, "Only for pending borrow stage");
    require(_collateralAsset != creditAsset, "Collateral asset and credit asset the same");
    
    uint balance = getBalance();
    require(balance >= creditAmount, "Not enough funds on the balance");

    collateralAsset = _collateralAsset;
    collateralAmount = _collateralAmount;

    require(IERC20(collateralAsset).transferFrom(tx.origin, address(this), collateralAmount), "The collateral asset is not transferred");
    
    borrower = tx.origin;
    state = State.repayment;

    IERC20(creditAsset).transfer(tx.origin, creditAmount);

    emit LogCreditBorrow(tx.origin, block.timestamp);

    return true;
  }

}