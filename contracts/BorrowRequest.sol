pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title BorrowRequest contract.
  * Inherits the Ownable contracts.
  */
contract BorrowRequest is Ownable {

  /** @dev Usings */
  // Using SafeMath for our calculations with uints.
  using SafeMath for uint;

  /** @dev State variables */
  // Borrower is the person who created the requests a loan.
  address borrower;

  address collateralAsset;

  uint collateralAmount;

  address requestedAsset;

  // Amount requested to be funded (in wei).
  uint requestedAmount;

  // Amount that will be returned by the borrower (including the interest).
  uint returnAmount;

  // Credit interest.
  uint interest;

  // The timestamp of credit creation.
  uint createDate;

  // When the loan will repaid
  uint returnDate;

  /** Stages that every credit contract gets trough.
    *   pendingCollateral - Collateral not paid
    *   pendingLends - During this state lends are allowed.
    *   repayment - During this stage only repayments are allowed. Borrower return asset to the contract.  
    *   interestReturns - This stage gives investors opportunity to request their returns. 
    *   finished - This is the stage when the contract is finished its purpose.    
  */
  enum State { pendingCollateral, pendingLends, repayment, interestReturns, finished }
  State state;

  // Storing the lenders for this credit.
  mapping(address => bool) public lenders;

  // Storing the invested amount by each lender.
  mapping(address => uint) lendersInvestedAmount;

  /** @dev Events
  *
  */
  event LogBorrowRequestInitialized(address indexed _address, uint indexed timestamp);  
  event LogBorrowRequestSetCollateral(address indexed _address, uint indexed timestamp);
  event LogBorrowRequestStateChanged(State indexed state, uint indexed timestamp);
  event LogLenderInvestment(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogBorrowerWithdrawal(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogBorrowerRepayment(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogLenderWithdrawal(address indexed _address, uint indexed _amount, uint indexed timestamp);

  /** @dev Modifiers
  *
  */
  modifier isPendingCollateral() {
    require(state == State.pendingCollateral, "Only for pending collateral");
    _;
  }

  modifier isSetCollateral() {
    require(state != State.pendingCollateral, "Only for pending collateral");
    _;
  }

  modifier isPendingLends() {
    require(state == State.pendingLends, "Only for pending lends");
    _;
  }

  modifier isNotReturnDate() {
    require(returnDate > block.timestamp, "Return date is less than current date");
    _;
  }

  modifier isActive() {
    require(state != State.finished);
    _;
  }

  modifier onlyBorrower() {
    require(msg.sender == borrower);
    _;
  }

  modifier canWithdraw() {
    require(getBalance() >= requestedAmount);
    _;
  }

  modifier canRepay() {
    require(state == State.repayment);
    _;
  }

  modifier onlyLender() {
    require(lenders[msg.sender] == true);
    _;
  }

  modifier canAskForInterest() {
    require(state == State.interestReturns);
    require(lendersInvestedAmount[msg.sender] > 0);
    _;
  }


  // @dev Constructor
  constructor(
    address _requestedAsset,
    uint _requestedAmount, 
    uint _interest,
    uint _returnDate
  ) public {
    require(_returnDate > block.timestamp, "Return date is less than current date");

    /** Set the borrower of the contract to the tx.origin
      * We are using tx.origin, because the contract is going to be published
      * by the main contract and msg.sender will break our logic.
    */
    borrower = tx.origin;

    requestedAsset = _requestedAsset;
    requestedAmount = _requestedAmount;
    interest = _interest;
    returnDate = _returnDate;

    /** Calculate the amount to be returned by the borrower.
      * At this point this is the addition of the requested amount and the interest.
      */
    returnAmount = requestedAmount.add(interest);

    // Set the initialization date.
    createDate = block.timestamp;

    state = State.pendingCollateral;

    // Log credit initialization.
    emit LogBorrowRequestInitialized(borrower, block.timestamp);
  }

  function setCollateral(address _collateralAsset, uint _collateralAmount) public isPendingCollateral onlyOwner returns(bool) {
    collateralAsset = _collateralAsset;
    collateralAmount = _collateralAmount;
    state = State.pendingLends;

    emit LogBorrowRequestSetCollateral(tx.origin, block.timestamp);

    return true;
  }

  function getBalance() public view returns(uint) {
    IERC20 requestedToken = IERC20(requestedAsset);

    return requestedToken.balanceOf(address(this));
  }

  function getInfo() public view returns (address, address, uint, address, uint, uint, uint, uint, uint, State, uint) {
    return (
      borrower,
      collateralAsset,
      collateralAmount,
      requestedAsset,
      requestedAmount,
      returnAmount,
      interest,
      createDate,
      returnDate,
      state,
      getBalance()
    );
  }

  function lend(uint amount) public onlyOwner isPendingLends isNotReturnDate returns (bool) {
    require(amount <= requestedAmount, "The amount is more than requested");

    IERC20 requestedToken = IERC20(requestedAsset);

    uint balance = getBalance();
    
    require(balance <= requestedAmount, "The balance is already more than requested");

    uint rest = requestedAmount.sub(balance);

    if (rest < amount) {
      amount = rest;
    }

    require(requestedToken.allowance(tx.origin, address(this)) >= amount, "Missing allowance");

    require(requestedToken.transferFrom(tx.origin, address(this), amount), "The requested asset is not transferred");

    if (balance.add(amount) >= requestedAmount) {
      state = State.repayment;
    }

    lenders[tx.origin] = true;
    lendersInvestedAmount[tx.origin] = lendersInvestedAmount[tx.origin].add(amount);

    LogLenderInvestment(tx.origin, amount, block.timestamp);

    return true;
  }

  /** @dev Withdraw function.
    * It can only be executed while contract is in active state.
    * It is only accessible to the borrower.
    * It is only accessible if the needed amount is gathered in the contract.
    * It can only be executed once.
    * Transfers the gathered amount to the borrower.
    */
  function withdraw() public isActive onlyBorrower canWithdraw returns (bool) {
    // Set the state to repayment so we can avoid reentrancy.
    state = State.repayment;

    uint balance = getBalance();

    // Log state change.
    LogBorrowRequestStateChanged(state, block.timestamp);

    // Log borrower withdrawal.
    LogBorrowerWithdrawal(msg.sender, balance, block.timestamp);

    IERC20 requestedToken = IERC20(requestedAsset);

    // Transfer the gathered amount to the credit borrower.
    requestedToken.transfer(borrower, balance);

    return true;
  }

  /** @dev Repayment function.
    * Allows borrower to make repayment to the contract.
    */
  function repay() public onlyBorrower canRepay returns (bool) {
    IERC20 requestedToken = IERC20(requestedAsset);

    require(requestedToken.allowance(msg.sender, address(this)) >= returnAmount, "Missing allowance");

    require(requestedToken.transferFrom(msg.sender, address(this), returnAmount), "The requested asset is not transferred");

    IERC20 collateralToken = IERC20(collateralAsset);

    collateralToken.transfer(borrower, collateralAmount);

    // Log borrower installment received.
    LogBorrowerRepayment(msg.sender, returnAmount, block.timestamp);

    // Set the credit state to "returning interests".
    state = State.interestReturns;

    return true;
  }

  /** @dev Request interest function.
    * It can only be executed while contract is in active state.
    * It is only accessible to lenders.
    * It is only accessible if lender funded 1 or more wei.
    * It can only be executed once.
    * Transfers the lended amount + interest to the lender.
    */
  function requestInterest() public isActive onlyLender canAskForInterest returns (bool) {

    // Calculate the amount to be returned to lender.
    //uint lenderReturnAmount = lendersInvestedAmount[msg.sender].mul(interest.div(requestedAmount.div(100)).add(100)).div(100);
    uint lenderReturnAmount = lendersInvestedAmount[msg.sender].mul(returnAmount).div(requestedAmount);

    uint balance = getBalance();

    // Assert the contract has enough balance to pay the lender.
    assert(balance >= lenderReturnAmount);

    lendersInvestedAmount[msg.sender] = 0;

    // Transfer the return amount with interest to the lender.
    IERC20 requestedToken = IERC20(requestedAsset);

    require(requestedToken.transfer(msg.sender, lenderReturnAmount), "The requested asset is not transferred");

    // Log the transfer to lender.
    LogLenderWithdrawal(msg.sender, lenderReturnAmount, block.timestamp);

    // Check if the contract balance is drawned.
    if (balance.sub(lenderReturnAmount) == 0) {
        // Set the contract stage to expired e.g. its lifespan is over.
        state = State.finished;

        // Log state change.
        LogBorrowRequestStateChanged(state, block.timestamp);
    }

    return true;
  }

}