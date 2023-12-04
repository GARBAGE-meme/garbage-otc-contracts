// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "src/interfaces/IChainLinkPriceFeed.sol";
import "src/GarbageSale.sol";

// @title Contract has same functionality as GarbageSale, but designed to replace it taking care of previous purchases
contract GarbageSaleV2 is Pausable, Ownable {
    struct User {
        uint256 ethSpent;
        uint256 tokensPurchased;
    }

    GarbageSale public immutable saleV1;// Address of previous GarbageSale
    IChainLinkPriceFeed public immutable priceFeed;// Address of ChainLink ETH/USD price feed

    uint256 public saleLimit;// Total amount of tokens to be sold
    uint256 public tokenPrice;// Price for single token in USD
    uint256 public totalTokensSold;// Total amount of purchased tokens

    mapping(address => User) public _users;// Stores the number of tokens purchased by each user and their claim status

    event TokensPurchased(
        address indexed user,
        uint256 indexed tokensAmount,
        uint256 indexed currentEthPrice
    );

    error ZeroPriceFeedAddress();
    error WrongOracleData();
    error TooLowValue();
    error PerWalletLimitExceeded(uint256 remainingLimit);
    error SaleLimitExceeded(uint256 remainingLimit);
    error NotEnoughEthOnContract();
    error EthSendingFailed();

    /*
        @notice Sets up contract while deploying
        @param _priceFeed: ChainLink ETH/USD oracle address
        @param _usdPrice: USD price for single token
        @param _saleLimit: Total amount of tokens to be sold during sale
        @param _owner: Address that will be defined as owner
        @param _saleV1: Address of previous GarbageSale
    **/
    constructor(
        address _priceFeed,
        uint256 _usdPrice,
        uint256 _saleLimit,
        address _owner,
        address _saleV1
    ) Ownable(_owner) {
        if (_priceFeed == address(0)) revert ZeroPriceFeedAddress();

        priceFeed = IChainLinkPriceFeed(_priceFeed);
        saleLimit = _saleLimit * 1e18;

        tokenPrice = _usdPrice;
        saleV1 = GarbageSale(payable(_saleV1));
    }

    /// @notice Pausing sale
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpausing sale
    function unpause() external onlyOwner {
        _unpause();
    }

    /*
        @notice Calculating sales on both previous and this contract
        @param _user: Address whose purchases should be calculated
        @return ethSpent: How many eth was spent by provided address for purchasing tokens
        @return tokenPurchased: How many tokens was purchased by provided address
    **/
    function users(address _user) public returns(uint256 ethSpent, uint256 tokenPurchased) {
        User memory user = _users[_user];
        (ethSpent, tokenPurchased) = saleV1.users(_user);
        ethSpent += user.ethSpent;
        tokenPurchased += user.tokensPurchased;
    }

    /*
        @notice Function for receiving ether
        @dev amount of tokens will be calculated from received value
    **/
    receive() external payable {
        if (msg.value < 0.1 ether) revert TooLowValue();
        (, uint256 purchased) = users(msg.sender);
        uint256 remainingLimit =  5 ether - _users[msg.sender].ethSpent;
        if (remainingLimit < msg.value) revert PerWalletLimitExceeded(remainingLimit);

        (uint256 ethPrice, uint256 tokensAmount) = convertETHToTokensAmount(msg.value);

        if (tokensAmount + totalTokensSold > saleLimit) revert SaleLimitExceeded(saleLimit - totalTokensSold);

        totalTokensSold += tokensAmount;
        _users[msg.sender].tokensPurchased += tokensAmount;
        _users[msg.sender].ethSpent += msg.value;

        (bool success, ) = payable(owner()).call{ value: msg.value }("");
        if (!success) revert EthSendingFailed();

        emit TokensPurchased(msg.sender, tokensAmount, ethPrice);
    }

    /*
        @notice Function for converting eth amount to equal tokens amount
        @param _ethAmount: Amount of eth to calculate
        @return ethPrice: Current eth price in usdt
        @return tokensAmount: Amount of tokens
    **/
    function convertETHToTokensAmount(uint256 _ethAmount) public view returns (uint256 ethPrice, uint256 tokensAmount) {
        (uint80 roundID, int256 price, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        ethPrice = uint256(price) / 1e2;

        if (answeredInRound < roundID
        || updatedAt < block.timestamp - 3 hours
            || price < 0) revert WrongOracleData();
        tokensAmount = _ethAmount * uint256(price) / tokenPrice / 1e2;
    }
}