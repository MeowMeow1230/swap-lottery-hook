// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";

/// @title Swap Lottery Hook
/// @notice Every swap enters a lottery. Dynamic-N triggers + multi-tier prizes.
/// @dev Hackathon MVP: uses block.prevrandao pseudo-random.
///      Production would use Chainlink VRF or API3 QRNG.
contract SwapLotteryHook is IHooks {
    using LPFeeLibrary for uint24;

    IPoolManager public immutable manager;

    // ── Lottery state ──
    uint256 public swapCount;
    uint256 public lotteryPool; // in currency1 units (18 decimals for ETH)

    // ── Constants ──
    uint24 public constant LP_FEE = 3000;         // 0.3%
    uint24 public constant LOTTERY_BPS = 1;       // 0.01% (1 basis point)
    uint256 public constant BASE_N = 100;          // base trigger interval
    uint256 public constant GRAND_BPS = 6000;      // 60% grand prize
    uint256 public constant CONSO_COUNT = 10;      // 10 consolation winners
    uint256 public constant CONSO_BPS = 400;       // 4% each

    // ── Winner log ──
    struct Record {
        address winner;
        uint256 amount;
        uint256 timestamp;
        bool isGrand;
    }
    Record[] public winners;
    uint256 public constant MAX_WINNERS = 20;

    // ── Events ──
    event SwapIn(
        address indexed swapper,
        uint256 count,
        uint256 pool,
        uint256 triggerN
    );
    event Draw(
        address indexed grand,
        uint256 grandPrize,
        uint256 consoEach,
        uint256 poolBefore
    );
    event Conso(address indexed w, uint256 amount);

    error OnlyPM();
    error Unsupported();

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    modifier onlyPM() {
        require(msg.sender == address(manager), OnlyPM());
        _;
    }

    // ── Unused hook stubs ──
    function beforeInitialize(address, PoolKey calldata, uint160) external override returns (bytes4) {
        revert Unsupported();
    }
    function beforeAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external override returns (bytes4) { revert Unsupported(); }
    function afterAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, BalanceDelta, BalanceDelta, bytes calldata)
        external override returns (bytes4, BalanceDelta) { revert Unsupported(); }
    function beforeRemoveLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external override returns (bytes4) { revert Unsupported(); }
    function afterRemoveLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, BalanceDelta, BalanceDelta, bytes calldata)
        external override returns (bytes4, BalanceDelta) { revert Unsupported(); }
    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external override returns (bytes4) { revert Unsupported(); }
    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external override returns (bytes4) { revert Unsupported(); }

    // ── Permissions (bits: afterSwap=6, afterSwapDelta=2) ──
    function getHookPermissions() public pure returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: true,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // ── Init ──
    function afterInitialize(address, PoolKey calldata key, uint160, int24)
        external override onlyPM returns (bytes4)
    {
        manager.updateDynamicLPFee(key, LP_FEE);
        return IHooks.afterInitialize.selector;
    }

    // ── Before swap: maintain fee ──
    function beforeSwap(address, PoolKey calldata key, SwapParams calldata, bytes calldata)
        external override onlyPM returns (bytes4, BeforeSwapDelta, uint24)
    {
        manager.updateDynamicLPFee(key, LP_FEE);
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    // ── After swap: the core ──
    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) external override onlyPM returns (bytes4, int128) {
        swapCount++;

        // Determine output (unspecified) currency & swap volume
        bool zfo = params.zeroForOne;
        Currency outCurrency = zfo ? key.currency1 : key.currency0;
        int128 amt0 = delta.amount0();
        int128 amt1 = delta.amount1();

        // Swap volume = absolute value of the amount the swapper receives
        // In V4: negative delta = swapper pays, positive = swapper receives
        uint256 swapVol;
        if (zfo) {
            // swapper pays currency0 (-), receives currency1 (+)
            swapVol = amt1 > 0 ? uint256(int256(amt1)) : uint256(int256(-amt0));
        } else {
            // swapper pays currency1 (-), receives currency0 (+)
            swapVol = amt0 > 0 ? uint256(int256(amt0)) : uint256(int256(-amt1));
        }

        // Lottery ticket: 0.01% (1 bps) of swap volume
        uint256 ticket = swapVol / 10000;
        lotteryPool += ticket;

        uint256 trigN = getDynamicN();
        emit SwapIn(sender, swapCount, lotteryPool, trigN);

        if (swapCount >= trigN && lotteryPool > 0) {
            _draw(key, outCurrency, sender);
            swapCount = 0;
        }

        // Claim ticket from swapper's output (hook accrues balance in PoolManager)
        return (IHooks.afterSwap.selector, int128(uint128(ticket)));
    }

    // ── Dynamic N: psychology curve ──
    function getDynamicN() public view returns (uint256) {
        if (lotteryPool == 0) return BASE_N;
        uint256 K = 100 ether;
        // N grows from BASE_N to 2*BASE_N as pool fills
        uint256 scale = (lotteryPool * 1e18) / (lotteryPool + K);
        return BASE_N + (BASE_N * scale) / 1e18;
    }

    // ── Lottery draw ──
    function _draw(PoolKey calldata key, Currency currency, address swapper)
        internal
    {
        uint256 pool = lotteryPool;

        uint256 grand = (pool * GRAND_BPS) / 10000;
        uint256 consoEach = (pool * CONSO_BPS) / 10000;
        uint256 totalPaid = grand + consoEach * CONSO_COUNT;

        lotteryPool = pool > totalPaid ? pool - totalPaid : 0;

        // Pay grand winner
        address gw = _pick(swapper, 0);
        _pay(currency, gw, grand);
        _log(gw, grand, true);

        // Pay consolation winners
        for (uint256 i = 0; i < CONSO_COUNT; i++) {
            address cw = _pick(swapper, i + 1);
            _pay(currency, cw, consoEach);
            emit Conso(cw, consoEach);
            if (i < 4) _log(cw, consoEach, false);
        }

        emit Draw(gw, grand, consoEach, pool);
    }

    // ── Pseudo-random pick ──
    function _pick(address swapper, uint256 seed) internal view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            block.prevrandao, block.timestamp, swapper,
            swapCount, seed, lotteryPool, block.gaslimit
        )))));
    }

    // ── Pay winner ──
    function _pay(Currency currency, address to, uint256 amt) internal {
        if (amt == 0 || to == address(0)) return;
        manager.take(currency, to, amt);
    }

    // ── Winner log ──
    function _log(address w, uint256 amt, bool grand) internal {
        if (winners.length >= MAX_WINNERS) {
            for (uint256 i = 0; i < MAX_WINNERS - 1; i++) {
                winners[i] = winners[i + 1];
            }
            winners.pop();
        }
        winners.push(Record(w, amt, block.timestamp, grand));
    }

    // ── Views ──
    function getWinners() external view returns (Record[] memory) {
        return winners;
    }

    function getProgress() external view returns (uint256 count, uint256 target) {
        return (swapCount, getDynamicN());
    }
}
