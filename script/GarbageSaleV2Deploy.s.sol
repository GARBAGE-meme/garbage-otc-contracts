// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/GarbageSale.sol";
import "src/GarbageSaleV2.sol";
import "lib/forge-std/src/Script.sol";

contract GarbageSaleDeployScript is Script {
    address public priceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    uint256 public tokenPrice = 20_000;
    uint256 public saleLimit = 50_000_000 - 4_285_930;
    address public owner = 0x50b8a37dc292F8AabE40BB0616337223F7ffAC37;
    address public saleV1 = 0x676917c754D0227439a4f99d7e85A7C90656410d;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        saleLimit -= GarbageSale(saleV1).totalTokensSold();
        require(saleLimit > 0, "Sale limit is less than 0");
        vm.startBroadcast(deployerPrivateKey);

        new GarbageSaleV2(priceFeed, tokenPrice, saleLimit, owner, saleV1);

        vm.stopBroadcast();
    }
}
