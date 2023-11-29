// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/GarbageSaleV2.sol";

contract GarbageSaleV2Testnet is GarbageSaleV2 {
    constructor(
        address _priceFeed,
        uint256 _usdPrice,
        uint256 _presaleLimit,
        address _owner,
        address _saleV2
    ) GarbageSaleV2(_priceFeed, _usdPrice, _presaleLimit, _owner, _saleV2) {}

    function resetUserTestnet(address _user) external {
        totalTokensSold -= _users[_user].tokensPurchased;
        delete _users[_user];
    }

    function setPresaleLimitTestnet(uint256 _presaleLimit) external {
        saleLimit = _presaleLimit;
    }
}
