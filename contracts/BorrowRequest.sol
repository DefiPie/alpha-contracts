pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

  /** @dev Modifiers
  *
  */
  modifier isPendingCollateral() {
      require(state == State.pendingCollateral);
      _;
  }


  // @dev Constructor
  constructor(
    address _requestedAsset,
    uint _requestedAmount, 
    uint _interest,
    uint _returnDate
  ) public {

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

  function getInfo() public view returns (address, address, uint, address, uint, uint, uint, uint, uint, uint, bool) {
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
      active
    );
  }

}
