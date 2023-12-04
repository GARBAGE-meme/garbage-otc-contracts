// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/test/GarbageSaleTestnet.sol";
import "src/test/ChainLinkPriceFeedMock.sol";
import "lib/forge-std/src/Script.sol";

contract GarbageSaleDeployTestnetScript is Script {
    uint256 public tokenPrice = 20_000;
    uint256 public saleLimit = 50_000_000;


    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        require(block.chainid == 11155111 || block.chainid == 5, "Should be deployed only on testnet");

        address priceFeed = address(new ChainLinkPriceFeedMock());

        new GarbageSaleTestnet(priceFeed, tokenPrice, saleLimit, vm.addr(deployerPrivateKey));

        vm.stopBroadcast();
    }
}
