// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/GarbageSale.sol";
import "lib/forge-std/src/Script.sol";

contract GarbageSaleDeployScript is Script {
    address public priceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    uint256 public tokenPrice = 20_000;
    uint256 public saleLimit = 50_000_000;
    address public owner = 0x50b8a37dc292F8AabE40BB0616337223F7ffAC37;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new GarbageSale(priceFeed, tokenPrice, saleLimit, owner);

        vm.stopBroadcast();
    }
}
