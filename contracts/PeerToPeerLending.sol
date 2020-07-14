pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './BorrowRequest.sol';
import './LendOffer.sol';

/** @title Peer to peer lending contract.
  * Inherits the Ownable contracts.
  */
contract PeerToPeerLending is Ownable {
    /** @dev Usings */
    // Using SafeMath for our calculations with uints.
    using SafeMath for uint;

    /** @dev State variables */

    // User structure
    struct User {        
      address[] borrowRequests;
      address[] lendOffers;
    }

    // We store all users in a mapping.
    mapping(address => User) private users;

    address[] public borrowRequests;
    address[] public lendOffers;

    /** @dev Events */
    event LogBorrowRequestCreated(address indexed _address, address indexed _borrower, uint indexed timestamp);
    event LogLendOffersRequestCreated(address indexed _address, address indexed _lender, uint indexed timestamp);


    /** @dev Borrow Request application function.
      * The function publishesh another contract which is the Borrow Request contract.
      * The owner of the new contract is the present contract.
      */
    function createBorrowRequest(
      address requestedAsset, 
      uint requestedAmount, 
      uint interest, 
      uint returnDate, 
      address collateralAsset, 
      uint collateralAmount,
      bytes32 description
    ) public returns(address) {
        // Create a new Borrow Request contract with the given parameters.
        BorrowRequest borrowRequest = new BorrowRequest(
          requestedAsset,
          requestedAmount,
          interest,
          returnDate,
          collateralAsset,
          collateralAmount,
          description
        );

        // Add the borrow request contract to our list with contracts.
        borrowRequests.push(address(borrowRequest));

        // Add the borrow request to the user's profile.
        users[msg.sender].borrowRequests.push(address(borrowRequest));

        // Log the borrow request creation event.
        emit LogBorrowRequestCreated(address(borrowRequest), msg.sender, block.timestamp);

        // Return the address of the newly created borrow request contract.
        return address(borrowRequest);
    }

    /** @dev Lend Offer application function.
      * The function publishesh another contract which is the Lend Offer contract.
      * The owner of the new contract is the present contract.
      */
    function createLendOffer(
      address offeredAsset,
      uint offeredAmount,
      uint interest,
      uint returnDate, 
      bytes32 description
    ) public returns(address) {
        // Create a new Lend Offer contract with the given parameters.
        LendOffer lendOffer = new LendOffer(
          offeredAsset,
          offeredAmount,
          interest,
          returnDate,
          description
        );

        // Add the Lend Offer contract to our list with contracts.
        lendOffers.push(address(lendOffer));

        // Add the Lend Offer to the user's profile.
        users[msg.sender].lendOffers.push(address(lendOffer));

        // Log the Lend Offer creation event.
        emit LogBorrowRequestCreated(address(lendOffer), msg.sender, block.timestamp);

        // Return the address of the newly created Lend Offer contract.
        return address(lendOffer);
    }

    /** @dev Get the list with all borrow requests.
      * @return borrowRequests Returns list of borrow requests addresses.
      */
    function getBorrowRequests() public view returns (address[] memory) {
        return borrowRequests;
    }

    /** @dev Get the list with all lend offers.
      * @return lendOffers Returns list of lend offers addresses.
      */
    function getLendOffers() public view returns (address[] memory) {
        return lendOffers;
    }

    /** @dev Get all users Borrow Requests.
      * @return users[msg.sender].BorrowRequests Return user Borrow Requests.
      */
    function getUserBorrowRequests() public view returns (address[] memory) {
        return users[msg.sender].borrowRequests;
    }

    /** @dev Get all users Lend Offers.
      * @return users[msg.sender].LendOffers Return user Lend Offers.
      */
    function getUserLendOffers() public view returns (address[] memory) {
        return users[msg.sender].lendOffers;
    }
}