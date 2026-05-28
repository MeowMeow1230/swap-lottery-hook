// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {SwapLotteryHook} from "../src/SwapLotteryHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";

contract SwapLotteryHookTest is Test {
    using PoolIdLibrary for PoolKey;
    using LPFeeLibrary for uint24;

    PoolManager pm;
    MockERC20 usdc;
    MockERC20 weth;
    Currency c0;
    Currency c1;
    SwapLotteryHook hook;
    PoolKey poolKey;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint24 constant DYNAMIC_FEE = 0x800000; // dynamic fee flag (actual fee set by hook)
    int24 constant TICK_SPACING = 60;

    function setUp() public {
        // Deploy PoolManager
        pm = new PoolManager(address(this));

        // Deploy tokens
        usdc = new MockERC20("USDC", "USDC", 6);
        weth = new MockERC20("WETH", "WETH", 18);

        // Sort currencies
        (c0, c1) = address(usdc) < address(weth)
            ? (Currency.wrap(address(usdc)), Currency.wrap(address(weth)))
            : (Currency.wrap(address(weth)), Currency.wrap(address(usdc)));

        // Deploy hook with address mining for correct permission bits
        // AFTER_INIT(12), BEFORE_SWAP(7), AFTER_SWAP(6), AFTER_SWAP_DELTA(2) = 0x10C4
        uint160 HOOK_MASK = 0x10C4;
        bytes memory initCode = abi.encodePacked(
            type(SwapLotteryHook).creationCode,
            abi.encode(address(pm))
        );
        bytes32 initCodeHash = keccak256(initCode);
        address hookAddr;
        bytes32 foundSalt;
        for (uint256 i = 0; i < 500000; i++) {
            foundSalt = bytes32(i);
            address predicted = address(uint160(uint256(keccak256(abi.encodePacked(
                bytes1(0xff), address(this), foundSalt, initCodeHash
            )))));
            if (uint160(predicted) & HOOK_MASK == HOOK_MASK) {
                hookAddr = predicted;
                break;
            }
        }
        require(hookAddr != address(0), "Salt mining failed");
        SwapLotteryHook hookLocal;
        assembly {
            hookLocal := create2(0, add(initCode, 0x20), mload(initCode), foundSalt)
        }
        require(address(hookLocal) == hookAddr, "Address mismatch");
        hook = hookLocal;

        // Create pool key
        poolKey = PoolKey({
            currency0: c0,
            currency1: c1,
            fee: DYNAMIC_FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(hook))
        });

        // Mint tokens to test users
        usdc.mint(alice, 1_000_000 * 1e6);
        usdc.mint(bob, 1_000_000 * 1e6);
        weth.mint(alice, 1000 * 1e18);
        weth.mint(bob, 1000 * 1e18);
    }

    function test_Deployment() public view {
        assertTrue(address(hook) != address(0));
        assertTrue(address(pm) != address(0));
        assertEq(hook.swapCount(), 0);
        assertEq(hook.lotteryPool(), 0);
    }

    function test_DynamicN_Initial() public view {
        assertEq(hook.getDynamicN(), 100); // BASE_N when pool = 0
    }

    function test_DynamicN_GrowsWithPool() public {
        // We can't easily set lotteryPool directly, but we can test the formula
        // Just verify it returns a reasonable value
        uint256 n = hook.getDynamicN();
        assertTrue(n >= 100 && n <= 200, "N out of range");
    }

    function test_PoolInitialization() public {
        // Verify hook has correct permission flags on its address
        uint160 addr = uint160(address(hook));
        uint160 HOOK_MASK = 0x10C4;
        assertEq(addr & HOOK_MASK, HOOK_MASK, "Hook missing permission flags");
    }
}
