// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/test/ChainLinkPriceFeedMock.sol";
import "src/GarbageSale.sol";
import "lib/forge-std/src/Test.sol";

contract GarbageSaleHarness is GarbageSale {
    constructor(
        address _priceFeed,
        uint256 _usdPrice,
        uint256 _presaleLimit,
        address _owner
    ) GarbageSale(_priceFeed, _usdPrice, _presaleLimit, _owner) {}

    function setSaleLimitHarness(uint256 _saleLimit) public {
        saleLimit = _saleLimit;
    }
}

abstract contract TestHelper is Test {
    ChainLinkPriceFeedMock public priceFeed;
    GarbageSaleHarness public saleContract;

    uint256 public tokenPrice = 20_000;
    uint256 public saleLimit = 50_000_000;

    address public owner = address(12345);

    error ZeroPriceFeedAddress();
    error WrongOracleData();
    error TooLowValue();
    error PerWalletLimitExceeded(uint256 remainingLimit);
    error SaleLimitExceeded(uint256 remainingLimit);
    error NotEnoughEthOnContract();
    error EthSendingFailed();

    function setUp() public virtual {
        priceFeed = new ChainLinkPriceFeedMock();
        vm.warp(1 days);
    }
}
