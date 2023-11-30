//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/interfaces/IChainLinkPriceFeed.sol";

contract ChainLinkPriceFeedMock is IChainLinkPriceFeed {
    int256 public price = 1500;

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = 1;
        answer = price * 1e6;
        startedAt = 2;
        updatedAt = block.timestamp;
        answeredInRound = 4;
    }

    function setPrice(int256 _price) external {
        price = _price;
    }
}
