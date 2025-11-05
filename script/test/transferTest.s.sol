// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {EIP3009Forwarder} from "../../src/EIP3009Forwarder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

/**
 * @notice Foundry script to test an already deployed EIP3009Forwarder contract on Base Sepolia
 * @dev This script:
 *  1. Uses a known signer (Alice) to sign an EIP-712 transfer authorization
 *  2. Uses a relayer wallet to broadcast transferWithAuthorization() on Base Sepolia
 *  3. Verifies the result
 */
contract TestDeployedForwarder is Script {
    // =============================================================
    //                      Config
    // =============================================================

    address constant FORWARDER = 0x47C0502f3b33ECA64383Da28F888E84e972b35Ec; // your deployed forwarder
    address constant TOKEN = 0xe37Df03ff6eE39530dfc20FC1900217Cbd162152; // token address

    uint256 constant TRANSFER_AMOUNT = 10e18; // 1 token
    address constant RECIPIENT = 0x38C867005D271Eb8Ea68F262ac64F1Bf336Ee2cf; // Example receiver

    uint256 alicePrivateKey;
    address alice;
    uint256 relayerPrivateKey;
    address relayer;

    bytes32 private constant TRANSFER_TYPEHASH =
        keccak256(
            "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
        );

    function setUp() public {
        // Load keys from environment variables or Foundry secrets
        alicePrivateKey = vm.envUint("ALICE_PRIVATE_KEY"); //0x0a46e23af2fd5a3bad07981ec019101b650cdd67
        relayerPrivateKey = vm.envUint("RELAYER_PRIVATE_KEY"); //contract deployer
        alice = vm.addr(alicePrivateKey);
        relayer = vm.addr(relayerPrivateKey);

        console.log("Alice:", alice);
        console.log("Relayer:", relayer);
    }

    function run() external {
        // vm.startBroadcast(alicePrivateKey);

        // // Approve forwarder to move Alice's tokens
        // IERC20(TOKEN).approve(FORWARDER, TRANSFER_AMOUNT);
        // console.log("Approved forwarder");

        // vm.stopBroadcast();

        vm.startBroadcast(relayerPrivateKey);

        EIP3009Forwarder forwarder = EIP3009Forwarder(FORWARDER);
        IERC20 token = IERC20(TOKEN);

        // Fetch domain separator
        bytes32 DOMAIN_SEPARATOR = forwarder.DOMAIN_SEPARATOR();
        console.logBytes32(DOMAIN_SEPARATOR);

        // Params
        uint256 validAfter = 0;
        uint256 validBefore = block.timestamp + 1 hours;
        bytes32 nonce = keccak256(abi.encodePacked(block.timestamp, alice));

        // Step 1. Alice signs off-chain (simulated here)
        bytes32 structHash = keccak256(
            abi.encode(
                TRANSFER_TYPEHASH,
                alice,
                RECIPIENT,
                TRANSFER_AMOUNT,
                validAfter,
                validBefore,
                nonce
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

        console.log("Signed digest:");

        console.log("v:", v);
        console.logBytes32(r);
        console.logBytes32(s);

        // Step 2. Ensure approval is set (done on-chain by Alice manually)
        uint256 allowance = token.allowance(alice, FORWARDER);
        console.log("Allowance:", allowance);

        // Step 3. Relayer submits transaction
        forwarder.transferWithAuthorization(
            alice,
            RECIPIENT,
            TRANSFER_AMOUNT,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );

        console.log("Transfer executed!");
        vm.stopBroadcast();
    }
}
