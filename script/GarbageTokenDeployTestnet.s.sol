// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/test/GarbageTokenTestnet.sol";
import "lib/forge-std/src/Script.sol";

contract GarbageTokenDeployTestnetScript is Script {
    uint256 public totalSupply = 100_000_000;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        require(block.chainid == 11155111 || block.chainid == 5, "Should be deployed only on testnet");

        new GarbageTokenTestnet(totalSupply, vm.addr(deployerPrivateKey));

        vm.stopBroadcast();
    }
}
