// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/GarbageSale.sol";

contract GarbageSaleTestnet is GarbageSale {
    function resetUserTestnet(address _user) external {
        totalTokensSold -= users[_user].tokensPurchased;
        delete users[_user];
    }

    function setPresaleLimitTestnet(uint256 _presaleLimit) external {
        saleLimit = _presaleLimit;
    }
}
