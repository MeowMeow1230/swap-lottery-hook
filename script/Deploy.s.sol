// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {SwapLotteryHook} from "../src/SwapLotteryHook.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/// @notice Deploys the full SwapLotteryHook stack to X Layer testnet.
contract DeployScript is Script {
    uint160 constant HOOK_MASK = 0x3FFF; // ALL_HOOK_MASK (14 bits)
    uint160 constant HOOK_BITS = 0x10C4; // exact bits: AFTER_INIT(12)+BEFORE_SWAP(7)+AFTER_SWAP(6)+AFTER_SWAP_DELTA(2)

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        console2.log("Deployer:", deployer);

        // STEP 0: Compute factory address (depends on deployer nonce)
        // Broadcast TX order: PoolManager(0), Token0(1), Token1(2), Factory(3)
        uint64 nonce = vm.getNonce(deployer);
        address pmAddr = _computeCreateAddress(deployer, nonce);
        address factoryAddr = _computeCreateAddress(deployer, nonce + 3);
        console2.log("Predicted PM:", pmAddr);
        console2.log("Predicted factory:", factoryAddr);

        // Pre-mine the hook salt using the predicted factory address
        bytes32 initCodeHash = keccak256(abi.encodePacked(
            type(SwapLotteryHook).creationCode,
            abi.encode(pmAddr)
        ));

        (bytes32 hookSalt, address hookAddr) = _mineSalt(factoryAddr, initCodeHash);
        console2.log("Hook salt found, predicted:", hookAddr);

        vm.startBroadcast(deployerKey);

        // 1. Deploy PoolManager
        PoolManager poolManager = new PoolManager(deployer);
        require(address(poolManager) == pmAddr, "PM addr mismatch");
        console2.log("PoolManager:", address(poolManager));

        // 2. Deploy test tokens
        MockERC20 token0 = new MockERC20("Test USDC", "USDC", 6);
        MockERC20 token1 = new MockERC20("Test WETH", "WETH", 18);
        console2.log("Token0:", address(token0));
        console2.log("Token1:", address(token1));

        (Currency c0, Currency c1) = address(token0) < address(token1)
            ? (Currency.wrap(address(token0)), Currency.wrap(address(token1)))
            : (Currency.wrap(address(token1)), Currency.wrap(address(token0)));

        // 3. Deploy HookFactory & hook
        HookFactory factory = new HookFactory();
        require(address(factory) == factoryAddr, "Factory addr mismatch");
        SwapLotteryHook hook = factory.deployWithSalt(
            IPoolManager(address(poolManager)), hookSalt
        );
        require(address(hook) == hookAddr, "Hook addr mismatch");
        console2.log("Hook:", address(hook));
        console2.log("Flags OK:", uint160(address(hook)) & HOOK_MASK == HOOK_BITS);

        // 4. Initialize pool
        uint24 dynamicFee = 0x800000;
        int24 tickSpacing = 60;

        PoolKey memory key = PoolKey({
            currency0: c0,
            currency1: c1,
            fee: dynamicFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(address(hook))
        });

        uint160 sqrtPriceX96 = 43390527552704682918107761388602;
        poolManager.initialize(key, sqrtPriceX96);
        console2.log("Pool initialized!");

        vm.stopBroadcast();

        console2.log("\n=== Deployed ===");
        console2.log("PoolManager:", address(poolManager));
        console2.log("Token0:     ", address(token0));
        console2.log("Token1:     ", address(token1));
        console2.log("Hook:       ", address(hook));
    }

    function _mineSalt(address factory, bytes32 initCodeHash)
        internal pure returns (bytes32 salt, address hookAddr)
    {
        for (uint256 i = 0; i < 500000; i++) {
            salt = bytes32(i);
            hookAddr = address(uint160(uint256(keccak256(abi.encodePacked(
                bytes1(0xff), factory, salt, initCodeHash
            )))));
            if (uint160(hookAddr) & HOOK_MASK == HOOK_BITS) {
                return (salt, hookAddr);
            }
        }
        revert("Salt mining failed");
    }

    function _computeCreateAddress(address sender, uint64 nonce)
        internal pure returns (address)
    {
        bytes memory data;
        if (nonce == 0) {
            // RLP: 0xd6 0x94 <sender> 0x80 (nonce 0 encoded as 0x80)
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), sender, bytes1(0x80));
        } else if (nonce <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), sender, bytes1(uint8(nonce)));
        } else if (nonce <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), sender, bytes1(0x81), bytes1(uint8(nonce)));
        } else if (nonce <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), sender, bytes1(0x82), bytes2(uint16(nonce)));
        } else if (nonce <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), sender, bytes1(0x83), bytes3(uint24(nonce)));
        } else {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), sender, bytes1(0x84), bytes4(uint32(nonce)));
        }
        return address(uint160(uint256(keccak256(data))));
    }
}

/// @notice Lightweight factory for CREATE2 deployment of SwapLotteryHook.
contract HookFactory {
    function deployWithSalt(IPoolManager pm, bytes32 salt)
        external returns (SwapLotteryHook)
    {
        bytes memory initCode = abi.encodePacked(
            type(SwapLotteryHook).creationCode,
            abi.encode(pm)
        );
        SwapLotteryHook h;
        assembly {
            h := create2(0, add(initCode, 0x20), mload(initCode), salt)
        }
        require(address(h) != address(0), "create2 failed");
        return h;
    }
}
