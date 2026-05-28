// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IUnlockCallback} from "@uniswap/v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

/// @notice Minimal swap tester for Uniswap V4 hook testing.
contract TestSwapper is IUnlockCallback {
    IPoolManager public immutable pm;
    MockERC20 public immutable token0;
    MockERC20 public immutable token1;

    bool public swapDone;
    int256 public swapResult0;
    int256 public swapResult1;

    constructor(IPoolManager _pm, MockERC20 _t0, MockERC20 _t1) {
        pm = _pm;
        token0 = _t0;
        token1 = _t1;
    }

    /// @notice Execute a swap: pay token0, receive token1. Returns (amount0Delta, amount1Delta)
    function testSwap(PoolKey calldata key, uint256 amountIn) external returns (int256, int256) {
        swapDone = false;
        bytes memory data = abi.encode(key, amountIn);
        pm.unlock(data);
        require(swapDone, "swap failed");
        return (swapResult0, swapResult1);
    }

    function unlockCallback(bytes calldata data) external override returns (bytes memory) {
        require(msg.sender == address(pm), "only PM");
        (PoolKey memory key, uint256 amountIn) = abi.decode(data, (PoolKey, uint256));

        // Swap: zeroForOne (token0 → token1), exact input
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -int256(amountIn),
            sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
        });

        BalanceDelta delta = pm.swap(key, params, bytes(""));
        swapResult0 = delta.amount0();
        swapResult1 = delta.amount1();

        // Settle: pay the negative delta (we owe token0)
        if (swapResult0 < 0) {
            token0.transfer(address(pm), uint256(int256(-swapResult0)));
            pm.settle();
        }

        // Take: receive the positive delta (we get token1)
        if (swapResult1 > 0) {
            pm.take(key.currency1, address(this), uint256(int256(swapResult1)));
        }

        swapDone = true;
        return bytes("");
    }

    // Allow contract to receive tokens from PoolManager.take()
    receive() external payable {}
}
