// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/DAIToken.sol";
import "forge-std/console.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DAIToken token = new DAIToken(1000000);
        console.log(address(token));
        vm.stopBroadcast();
    }
}

// Contract Address: 0x4c3edEF8422EC0c4C70B5A47d4a81e421DD6CeFA
//  URL: https://sepolia.etherscan.io/address/0x4c3edef8422ec0c4c70b5a47d4a81e421dd6cefa
