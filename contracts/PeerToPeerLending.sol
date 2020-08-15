pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20Detailed.sol";
import './Credit.sol';
import './IOracle.sol';

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
      address[] borrowRequestsLender;
      address[] lendOffersBorrower;
    }

    // We store all users in a mapping.
    mapping(address => User) private users;

    address[] public borrowRequests;
    address[] public lendOffers;

    address public oracleAddress;

    /** @dev Events */
    event LogCreditCreated(address indexed _address, Credit.AppType appType, address indexed _borrower, uint indexed timestamp);        

    constructor(address _oracleAddress) public {
      oracleAddress = _oracleAddress;
    }

    function setOracle(address _oracleAddress) public onlyOwner returns(bool) {
      oracleAddress = _oracleAddress;
    }

    /** @dev Borrow Request application function.
      * The function publishesh another contract which is the Borrow Request contract.
      * The owner of the new contract is the present contract.
      */
    function createBorrowRequest(
      address creditAsset, 
      uint creditAmount, 
      uint interest, 
      uint returnDate, 
      address collateralAsset, 
      uint collateralAmount
    ) public returns(address) {

      require(collateralAsset != creditAsset, "Collateral asset and requested asset the same");

      IERC20Detailed collateralToken = IERC20Detailed(collateralAsset);

      IOracle oracle = IOracle(oracleAddress);

      address _creditAsset = creditAsset;

      require(
        oracle.getPrice(collateralAsset).mul(collateralAmount).div(uint(10) ** collateralToken.decimals()) >= 
        oracle.getPrice(_creditAsset).mul(creditAmount).div(uint(10) ** IERC20Detailed(_creditAsset).decimals()).mul(2), 
        "Not enough collateral"
      );

      require(collateralToken.transferFrom(msg.sender, address(this), collateralAmount), "The collateral asset is not transferred");
      
      Credit credit = new Credit(
        Credit.AppType.borrowRequest,
        creditAsset,
        creditAmount,
        interest,
        returnDate
      );

      collateralToken.transfer(address(credit), collateralAmount);
      
      credit.setCollateral(collateralAsset, collateralAmount);

      // Add the borrow request contract to our list with contracts.
      borrowRequests.push(address(credit));

      // Add the borrow request to the user's profile.
      users[msg.sender].borrowRequests.push(address(credit));

      // Log the borrow request creation event.
      emit LogCreditCreated(address(credit), Credit.AppType.borrowRequest, msg.sender, block.timestamp);

      // Return the address of the newly created borrow request contract.
      return address(credit);
    }

    /** @dev Lend Offer application function.
      * The function publishesh another contract which is the Lend Offer contract.
      * The owner of the new contract is the present contract.
      */
    function createLendOffer(
      address creditAsset,
      uint creditAmount,
      uint interest,
      uint returnDate
    ) public returns(address) {
      IERC20Detailed creditToken = IERC20Detailed(creditAsset);

      require(creditToken.transferFrom(msg.sender, address(this), creditAmount), "The offered asset is not transferred");

      // Create a new Lend Offer contract with the given parameters.
      Credit credit = new Credit(
        Credit.AppType.lendOffer,
        creditAsset,
        creditAmount,
        interest,
        returnDate
      );

      creditToken.transfer(address(credit), creditAmount);

      credit.setAsset();

      // Add the Lend Offer contract to our list with contracts.
      lendOffers.push(address(credit));

      // Add the Lend Offer to the user's profile.
      users[msg.sender].lendOffers.push(address(credit));

      // Log the Lend Offer creation event.
      emit LogCreditCreated(address(credit), Credit.AppType.lendOffer, msg.sender, block.timestamp);

      // Return the address of the newly created Lend Offer contract.
      return address(credit);
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

    function lendToBorrowRequest(address _borrowRequest) public {
      Credit credit = Credit(_borrowRequest);

      require(credit.lend(), "lendToBorrowRequest error");

      users[msg.sender].borrowRequestsLender.push(_borrowRequest);
    }

    function borrowToLendOffer(address _lendOffer, address collateralAsset, uint collateralAmount) public {
      IOracle oracle = IOracle(oracleAddress);
      IERC20Detailed collateralToken = IERC20Detailed(collateralAsset);
      Credit credit = Credit(_lendOffer);

      address creditAsset = credit.getCreditAsset();
      uint creditAmount = credit.getCreditAmount();

      require(
        oracle.getPrice(collateralAsset).mul(collateralAmount).div(uint(10) ** collateralToken.decimals()) >= 
        oracle.getPrice(creditAsset).mul(creditAmount).div(uint(10) ** IERC20Detailed(creditAsset).decimals()).mul(2),
        "Not enough collateral"
      );

      require(credit.borrow(collateralAsset, collateralAmount));

      users[msg.sender].lendOffersBorrower.push(_lendOffer);
    }

    function getUserLendsToBorrowRequests() public view returns (address[] memory) {
      return users[msg.sender].borrowRequestsLender;
    }

    function getUserBorrowToLendOffers() public view returns (address[] memory) {
      return users[msg.sender].lendOffersBorrower;
    }
}