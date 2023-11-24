// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/test/GarbageTokenTestnet.sol";
import "lib/forge-std/src/Script.sol";

contract GarbageTokenDeployScript is Script {
    uint256 public totalSupply = 100_000_000;
    address public owner = 0xe4aedfc70D4B34182E1017B3ec0389aA7Cc9b5FA;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new GarbageTokenTestnet(totalSupply, owner);

        vm.stopBroadcast();
    }
}
