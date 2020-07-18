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

  // Currently repaid amount.
  uint repaidAmount;

  // Credit interest.
  uint interest;

  // The timestamp of credit creation.
  uint createDate;

  // When the loan will repaid
  uint returnDate;

  // The timestamp of last repayment date.
  uint lastRepaymentDate;

  // Active state of the credit.
  bool active = true;

  /** Stages that every credit contract gets trough.
    *   pendingCollateral - Collateral not paid
    *   pendingLends - During this state lends are allowed.
    *   repayment - During this stage only repayments are allowed.    
    *   finished - This is the stage when the contract is finished its purpose.    
  */
  enum State { pendingCollateral, pendingLends, repayment, finished }
  State state;

  // Storing the lenders for this credit.
  mapping(address => bool) public lenders;

  // Storing the invested amount by each lender.
  mapping(address => uint) lendersInvestedAmount;

  // Store the lenders count, later needed for revoke vote.
  uint lendersCount = 0;

  /** @dev Events
  *
  */
  event LogBorrowRequestInitialized(address indexed _address, uint indexed timestamp);  
  event LogBorrowRequestSetCollateral(address indexed _address, uint indexed timestamp);
  event LogCreditStateChanged(State indexed state, uint indexed timestamp);
  event LogLenderInvestment(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogBorrowerWithdrawal(address indexed _address, uint indexed _amount, uint indexed timestamp);

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
    require(active == true);
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

  function setCollateral(address _collateralAsset, uint _collateralAmount) public isPendingCollateral onlyOwner {
      collateralAsset = _collateralAsset;
      collateralAmount = _collateralAmount;
      state = State.pendingLends;

      emit LogBorrowRequestSetCollateral(tx.origin, block.timestamp);
  }

  function getBalance() public view isSetCollateral returns(uint) {
    IERC20 requestedToken = IERC20(requestedAsset);

    return requestedToken.balanceOf(address(this));
  }

  function getInfo() public view returns (address, address, uint, address, uint, uint, uint, uint, uint, uint, bool, State, uint) {
    return (
      borrower,
      collateralAsset,
      collateralAmount,
      requestedAsset,
      requestedAmount,
      returnAmount,
      repaidAmount,
      interest,
      createDate,
      returnDate,
      active,
      state,
      getBalance()
    );
  }

  function lend(uint amount) public isPendingLends isNotReturnDate {
    require(amount <= requestedAmount, "The amount is more than requested");

    IERC20 requestedToken = IERC20(requestedAsset);

    uint balance = getBalance();
    
    require(balance <= requestedAmount, "The balance is already more than requested");

    uint rest = requestedAmount.sub(balance);

    if (rest < amount) {
      amount = rest;
    }

    require(requestedToken.allowance(msg.sender, address(this)) >= amount, "Missing allowance");

    require(requestedToken.transferFrom(msg.sender, address(this), amount), "The requested asset is not transferred");

    if (balance.add(amount) >= requestedAmount) {
      state = State.repayment;
    }

    lenders[msg.sender] = true;
    lendersCount++;
    lendersInvestedAmount[msg.sender] = lendersInvestedAmount[msg.sender].add(amount);

    LogLenderInvestment(msg.sender, amount, block.timestamp);
  }

  /** @dev Withdraw function.
      * It can only be executed while contract is in active state.
      * It is only accessible to the borrower.
      * It is only accessible if the needed amount is gathered in the contract.
      * It can only be executed once.
      * Transfers the gathered amount to the borrower.
      */
    function withdraw() public isActive onlyBorrower canWithdraw {
        // Set the state to repayment so we can avoid reentrancy.
        state = State.repayment;

        uint balance = getBalance();

        // Log state change.
        LogCreditStateChanged(state, block.timestamp);

        // Log borrower withdrawal.
        LogBorrowerWithdrawal(msg.sender, balance, block.timestamp);

        IERC20 requestedToken = IERC20(requestedAsset);

        // Transfer the gathered amount to the credit borrower.
        requestedToken.transfer(borrower, balance);
    }

}
