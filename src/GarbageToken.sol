// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GarbageToken is ERC20 {
    constructor(uint256 _initialSupply) ERC20("Garbage Token", "$GARBAGE") {
        _mint(msg.sender, _initialSupply * 10 ** decimals());
    }
}
