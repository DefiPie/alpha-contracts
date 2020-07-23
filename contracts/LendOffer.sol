pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './Oracle.sol';

/** @title Lend contract.
  * Inherits the Ownable contracts.
  */
contract LendOffer is Ownable {

  /** @dev Usings */
  // Using SafeMath for our calculations with uints.
  using SafeMath for uint;

  /** @dev State variables */
  // Lender is the person who generated the credit offer.
  address lender;

  address offeredAsset;

  uint offeredAmount;

  // Amount that will be returned by the borrower (including the interest).
  uint returnAmount;

  // Credit interest.
  uint interest;

  // The timestamp of offer creation.
  uint createDate;

  // When the loan will repaid
  uint returnDate;

  enum State { pendingAsset, pendingBorrow, repayment, returnAsset, finished }
  State state;

  // Storing the borrowers for this credit.
  mapping(address => bool) public borrowers;

  // Storing the invested amount by each borrower.
  mapping(address => uint) borrowersGotAmount;

  // collateral structure
  struct Collateral {
    address asset;
    uint amount;
  }

  // Storing the invested amount by each borrower.
  mapping(address => Collateral) borrowersCollateral;

  /** @dev Events
  *
  */
  event LogLendOfferInitialized(address indexed _address, uint indexed timestamp);
  event LogLendOfferSetAsset(address indexed _address, uint indexed timestamp);
  event LogLendOfferBorrow(address indexed _address, uint amount, uint indexed timestamp);
  event LogLendOfferRepayment(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogLendOfferReturnAsset(address indexed _address, uint indexed _amount, uint indexed timestamp);

  /** @dev Modifiers
  *
  */
  modifier isPendingAsset() {
    require(state == State.pendingAsset, "Only for pending asset");
    _;
  }

  modifier isPendingBorrow() {
    require(state == State.pendingBorrow, "Only for pending borrow");
    _;
  }

  modifier isNotReturnDate() {
    require(returnDate > block.timestamp, "Return date is less than current date");
    _;
  }

  modifier onlyBorrower() {
    require(borrowers[msg.sender] == true);
    _;
  }

  modifier canRepay() {
    require(state == State.repayment);
    _;
  }

  modifier isBorrowerHasDebt() {
    require(borrowersGotAmount[msg.sender] > 0);
    _;
  }

  modifier onlyLender() {
    require(msg.sender == lender);
    _;
  }

  modifier canReturnAsset() {
    require(state == State.returnAsset);
    require(getBalance() >= returnAmount);
    _;
  }

  // @dev Constructor.
  constructor(
    uint _interest,
    uint _returnDate
  ) public {
    require(_returnDate > block.timestamp, "Return date is less than current date");

    /** Set the lender of the contract to the tx.origin
      * We are using tx.origin, because the contract is going to be published
      * by the main contract and msg.sender will break our logic.
    */
    lender = tx.origin;

    // Set the interest for the credit.
    interest = _interest;
    returnDate = _returnDate;
    
    // Set the initialization date.
    createDate = block.timestamp;

    state = State.pendingAsset;

    // Log credit initialization.
    emit LogLendOfferInitialized(lender, block.timestamp);
  }

  function setAsset(address _offeredAsset, uint _offeredAmount) public isPendingAsset onlyOwner {
    offeredAsset = _offeredAsset;
    offeredAmount = _offeredAmount;
    returnAmount = offeredAmount.add(interest);
    state = State.pendingBorrow;

    emit LogLendOfferSetAsset(tx.origin, block.timestamp);
  }

  function getBalance() public view returns(uint) {
    IERC20 offeredToken = IERC20(offeredAsset);

    return offeredToken.balanceOf(address(this));
  }

  function getOfferedAsset() public view returns (address) {
    return offeredAsset;
  }

  function getInfo() public view returns (address, address, uint, uint, uint, uint, uint, State, uint) {
    return (
      lender,
      offeredAsset,
      offeredAmount,
      returnAmount,
      interest,
      createDate,
      returnDate,
      state,
      getBalance()
    );
  }

  function borrow(uint amount, address collateralAsset, uint collateralAmount) public onlyOwner isPendingBorrow isNotReturnDate returns (bool) {
    require(collateralAsset != offeredAsset, "Collateral asset and offered asset the same");

    require(amount < offeredAmount, "The amount taken is greater than the amount offered");

    if (borrowersCollateral[tx.origin].asset != address(0)) {
      require(borrowersCollateral[tx.origin].asset == collateralAsset, "The сollateral asset does not match the previously provided");
    }
    
    uint assetBalance = getBalance();
    require(assetBalance > 0, "The asset balance is already empty");    

    if (amount > assetBalance) {
      amount = assetBalance;
    }

    IERC20 collateralToken = IERC20(collateralAsset);

    require(collateralToken.transferFrom(tx.origin, address(this), collateralAmount), "The collateral asset is not transferred");

    if (assetBalance.sub(amount) == 0) {
      state = State.repayment;
    }

    borrowers[tx.origin] = true;
    borrowersGotAmount[tx.origin] = borrowersGotAmount[tx.origin].add(amount);
    if (borrowersCollateral[tx.origin].asset != address(0)) {
      borrowersCollateral[tx.origin].asset = collateralAsset;
    }
    borrowersCollateral[tx.origin].amount = borrowersCollateral[tx.origin].amount.add(collateralAmount);

    IERC20 offeredToken = IERC20(offeredAsset);
    offeredToken.transfer(tx.origin, amount);

    emit LogLendOfferBorrow(tx.origin, amount, block.timestamp);

    return true;
  }

  function repay() public onlyBorrower canRepay isBorrowerHasDebt {
    IERC20 offeredToken = IERC20(offeredAsset);

    uint borrowerReturnAmount = borrowersGotAmount[msg.sender].mul(returnAmount).div(offeredAmount);

    uint balance = getBalance();

    require(offeredToken.transferFrom(msg.sender, address(this), borrowerReturnAmount), "The offered asset is not transferred");

    borrowersGotAmount[msg.sender] = 0;
    borrowersCollateral[msg.sender].amount = 0;

    IERC20 collateralToken = IERC20(borrowersCollateral[msg.sender].asset);

    collateralToken.transfer(msg.sender, borrowersCollateral[msg.sender].amount);

    if (balance.add(borrowerReturnAmount) >= returnAmount) {
      state = State.returnAsset;
    }

    // Log borrower installment received.
    emit LogLendOfferRepayment(msg.sender, borrowerReturnAmount, block.timestamp);
  }

  function returnAsset() public onlyLender canReturnAsset {
    uint balance = getBalance();
    IERC20 offeredToken = IERC20(offeredAsset);
    offeredToken.transfer(lender, balance);
    state = State.finished;

    emit LogLendOfferReturnAsset(msg.sender, balance, block.timestamp);
  }

}
