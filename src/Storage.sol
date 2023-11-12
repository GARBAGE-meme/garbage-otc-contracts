// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "src/interfaces/IChainLinkPriceFeed.sol";

abstract contract Storage is Pausable, Ownable {
    struct User {
        uint256 ethSpent;
        uint256 tokensPurchased;
    }

    IChainLinkPriceFeed public priceFeed;// Address of ChainLink ETH/USD price feed

    uint256 public saleLimit;// Total amount of tokens to be sold
    uint256 public tokenPrice;// Price for single token in USD
    uint256 public totalTokensSold;// Total amount of purchased tokens

    mapping(address => User) public users;// Stores the number of tokens purchased by each user and their claim status

    address public activeImplementation;
    bool public initialized;
}
