// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/GarbageSale.sol";

contract GarbageSaleTestnet is GarbageSale {
    constructor(
        address _priceFeed,
        uint256 _usdPrice,
        uint256 _presaleLimit,
        address _owner,
        address _saleV2
    ) GarbageSale(_priceFeed, _usdPrice, _presaleLimit, _owner, _saleV2) {}

    function resetUserTestnet(address _user) external {
        totalTokensSold -= users[_user].tokensPurchased;
        delete users[_user];
    }

    function setPresaleLimitTestnet(uint256 _presaleLimit) external {
        saleLimit = _presaleLimit;
    }
}
