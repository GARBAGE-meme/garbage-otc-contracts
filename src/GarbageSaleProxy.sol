// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/Storage.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

contract GarbageSaleProxy is Proxy, Storage  {

    constructor(address _activeImplementation) Ownable(msg.sender) {
        activeImplementation = _activeImplementation;
    }

    function _implementation() internal view override returns (address) {
        return activeImplementation;
    }

    function upgrade(address _newImplementation) public onlyOwner {
        require(_newImplementation != address(0), "Zero implementation address");
        activeImplementation = _newImplementation;
        initialized = false;
    }
}
