// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/ARBToken.sol";
import "forge-std/console.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ARBToken token = new ARBToken(1000000);
        console.log(address(token));
        vm.stopBroadcast();
    }
}

// Contract Address: 0xDFF9ed797227cda6adCBdbe396c56B063ca59055
// URL: https://sepolia.etherscan.io/address/0xdff9ed797227cda6adcbdbe396c56b063ca59055
