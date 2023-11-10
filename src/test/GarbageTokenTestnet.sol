// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/GarbageToken.sol";

contract GarbageTokenTestnet is GarbageToken {

    constructor(uint256 _initialSupply) GarbageToken(_initialSupply){}

    function burnTestnet(address _user, uint256 _amount) external {
        _burn(_user, _amount);
    }

    function mintTestnet(address _user, uint256 _amount) external {
        _mint(_user, _amount);
    }
}
