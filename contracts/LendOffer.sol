pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** @title Lend contract.
  * Inherits the Ownable contracts.
  */
contract LendOffer is Ownable {

  /** @dev Usings */
  // Using SafeMath for our calculations with uints.
  using SafeMath for uint;

  /** @dev State variables */
  // Lender is the person who generated the credit offer.
  address public lender;

  address public offeredAsset;

  uint public offeredAmount;

  // Amount that will be returned by the borrower (including the interest).
  uint public returnAmount;

  // Currently repaid amount.
  uint public repaidAmount;

  // Credit interest.
  uint public interest;

  // The timestamp of offer creation.
  uint public createDate;

  // When the loan will repaid
  uint public returnDate;

  // The timestamp of last repayment date.
  uint public lastRepaymentDate;

  // Active state of the credit.
  bool public active = true;

  // Storing the borrowers for this credit.
  mapping(address => bool) public borrowers;

  // Storing the invested amount by each borrower.
  mapping(address => uint) public borrowersInvestedAmount;

  // Store the borrowers count, later needed for revoke vote.
  uint public borrowersCount = 0;

  /** @dev Events
  *
  */
  event LogLendOfferInitialized(address indexed _address, uint indexed timestamp);

  // @dev Constructor.
  constructor(
    address _offeredAsset,
    uint _offeredAmount,
    uint _interest,
    uint _returnDate
  ) public {

    /** Set the lender of the contract to the tx.origin
      * We are using tx.origin, because the contract is going to be published
      * by the main contract and msg.sender will break our logic.
    */
    lender = tx.origin;

    offeredAsset = _offeredAsset;

    offeredAmount = _offeredAmount;

    // Set the interest for the credit.
    interest = _interest;

    returnDate = _returnDate;

    /** Calculate the amount to be returned by the borrower.
      * At this point this is the addition of the requested amount and the interest.
      */
    returnAmount = offeredAmount.add(interest);

    // Set the initialization date.
    createDate = block.timestamp;

    // Log credit initialization.
    emit LogLendOfferInitialized(lender, block.timestamp);
  }

  function getInfo() public view returns (address, address, uint, uint, uint, uint, uint, uint, bool) {
    return (
      lender,
      offeredAsset,
      offeredAmount,
      returnAmount,
      repaidAmount,
      interest,
      createDate,
      returnDate,
      active
    );
  }

}
