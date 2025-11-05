// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MetaOrg} from "../src/mock/erc20.sol";

contract DeployMyToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the ERC20 token with initial supply of 1 million tokens
        new MetaOrg(
            0xA86885BFbdA1998Ec90911a4f0753EB7e61C7589,
            0xA86885BFbdA1998Ec90911a4f0753EB7e61C7589
        );

        vm.stopBroadcast();
    }
}
