// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {SwapLotteryHook} from "../src/SwapLotteryHook.sol";

/// @notice Mint test tokens, approve PoolManager, and verify hook state.
contract TestSwapScript is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(key);
        console2.log("Deployer:", deployer);

        vm.startBroadcast(key);

        MockERC20 usdc = MockERC20(0xC67958F2329f4C289aa43D52577C0aF32Dbae028);
        MockERC20 weth = MockERC20(0x24003ccc694FF272e54b1601C68019d0E1639eBb);
        SwapLotteryHook hook = SwapLotteryHook(0x2D782F42A0a8bBc6b7526aC2272728976Eee90C4);
        address pm = 0x124850dA551dC83b124A9A3F84f8D6674C870Ba1;

        // Mint test tokens
        usdc.mint(deployer, 1_000_000 * 1e6);
        weth.mint(deployer, 100 * 1e18);
        console2.log("Minted 1M USDC + 100 WETH");

        // Approve PoolManager
        usdc.approve(pm, type(uint256).max);
        weth.approve(pm, type(uint256).max);
        console2.log("Approved PoolManager");

        // Hook state
        console2.log("swapCount:", hook.swapCount());
        console2.log("lotteryPool:", hook.lotteryPool());
        console2.log("getDynamicN():", hook.getDynamicN());

        (uint256 progress, uint256 target) = hook.getProgress();
        console2.log("getProgress:", progress, "/", target);

        vm.stopBroadcast();
    }
}
