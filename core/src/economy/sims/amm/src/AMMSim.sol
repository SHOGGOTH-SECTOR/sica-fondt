// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

library AMMSim {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant BPS = 10_000;

    struct Pool {
        uint256 x;
        uint256 y;
        uint256 feeBps;
    }

    function amountOut(uint256 x, uint256 y, uint256 dx, uint256 feeBps) internal pure returns (uint256 dy) {
        require(x > 0 && y > 0 && dx > 0 && feeBps < BPS, "bad pool");
        uint256 dxEff = dx * (BPS - feeBps) / BPS;
        dy = y * dxEff / (x + dxEff);
        require(dy < y, "drain");
    }

    function sqrt(uint256 a) internal pure returns (uint256 z) {
        if (a == 0) return 0;
        z = 1 << ((log2(a) + 1) >> 1);
        unchecked {
            for (uint256 i=0; i<7; ++i) z = (z + a/z) >> 1;
            uint256 z1 = a/z;
            if (z1 < z) z = z1;
        }
    }
    function log2(uint256 x) internal pure returns (uint256 r) {
        while (x > 1) { x >>= 1; ++r; }
    }

    function impermanentLossWad(uint256 ratioWad) internal pure returns (int256) {
        require(ratioWad > 0, "ratio");
        uint256 rootWad = sqrt(ratioWad * WAD);
        uint256 relativeWad = 2 * rootWad * WAD / (WAD + ratioWad);
        return int256(relativeWad) - int256(WAD);
    }

    function slippageWad(uint256 x, uint256 y, uint256 dx, uint256 feeBps) internal pure returns (uint256) {
        uint256 dy = amountOut(x,y,dx,feeBps);
        uint256 spotWad = y * WAD / x;
        uint256 execWad = dy * WAD / dx;
        return execWad >= spotWad ? 0 : (spotWad-execWad)*WAD/spotWad;
    }

    function lpShouldWithdraw(uint256 feeIncomeWad, uint256 ratioWad) internal pure returns (bool) {
        int256 il = impermanentLossWad(ratioWad);
        uint256 loss = il < 0 ? uint256(-il) : 0;
        return loss > feeIncomeWad;
    }


    /// @notice Token amounts represented by concentrated liquidity L at a
    /// current sqrt-price. All sqrt-prices are WAD-scaled.
    function concentratedAmounts(
        uint256 liquidity,
        uint256 sqrtLowerWad,
        uint256 sqrtPriceWad,
        uint256 sqrtUpperWad
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        require(
            liquidity > 0 &&
            sqrtLowerWad > 0 &&
            sqrtLowerWad < sqrtUpperWad,
            "bad range"
        );

        if (sqrtPriceWad <= sqrtLowerWad) {
            amount0 =
                liquidity *
                (sqrtUpperWad - sqrtLowerWad) /
                sqrtLowerWad *
                WAD /
                sqrtUpperWad;
            return (amount0, 0);
        }

        if (sqrtPriceWad >= sqrtUpperWad) {
            amount1 =
                liquidity *
                (sqrtUpperWad - sqrtLowerWad) /
                WAD;
            return (0, amount1);
        }

        amount0 =
            liquidity *
            (sqrtUpperWad - sqrtPriceWad) /
            sqrtPriceWad *
            WAD /
            sqrtUpperWad;
        amount1 =
            liquidity *
            (sqrtPriceWad - sqrtLowerWad) /
            WAD;
    }

    function _amountOutOrZero(
        uint256 x,
        uint256 y,
        uint256 dx,
        uint256 feeBps
    ) private pure returns (uint256) {
        if (dx == 0) return 0;
        return amountOut(x, y, dx, feeBps);
    }

    function _marginalOutWad(
        uint256 x,
        uint256 y,
        uint256 dx,
        uint256 feeBps
    ) private pure returns (uint256) {
        require(x > 0 && y > 0 && feeBps < BPS, "bad pool");
        uint256 gamma = BPS - feeBps;
        uint256 dxEff = dx * gamma / BPS;
        uint256 denom = x + dxEff;

        // d(amountOut)/d(raw input), WAD-scaled. Keeping the divisions late
        // preserves enough precision for the router without floating point.
        return y * x * gamma * WAD / BPS / denom / denom;
    }

    /// @notice Split one exact-input swap across two constant-product pools.
    /// The optimum is where their marginal outputs equalize; binary search is
    /// deterministic because each pool's marginal output is monotone.
    function _routeOutput(
        Pool memory a,
        Pool memory b,
        uint256 dx,
        uint256 splitA
    ) private pure returns (uint256) {
        return
            _amountOutOrZero(a.x, a.y, splitA, a.feeBps) +
            _amountOutOrZero(b.x, b.y, dx - splitA, b.feeBps);
    }

    function _bestSplit(
        Pool memory a,
        Pool memory b,
        uint256 dx
    ) private pure returns (uint256 splitA, uint256 totalOut) {
        uint256 lo = 0;
        uint256 hi = dx;

        for (uint256 i = 0; i < 64 && lo < hi; ++i) {
            uint256 mid = lo + (hi - lo) / 2;
            if (
                _marginalOutWad(a.x, a.y, mid, a.feeBps) >
                _marginalOutWad(b.x, b.y, dx - mid, b.feeBps)
            ) {
                lo = mid + 1;
            } else {
                hi = mid;
            }
        }

        splitA = lo;
        totalOut = _routeOutput(a, b, dx, splitA);

        if (splitA > 0) {
            uint256 alt = splitA - 1;
            uint256 altOut = _routeOutput(a, b, dx, alt);
            if (altOut > totalOut) {
                splitA = alt;
                totalOut = altOut;
            }
        }

        uint256 onlyA = _routeOutput(a, b, dx, dx);
        if (onlyA > totalOut) {
            splitA = dx;
            totalOut = onlyA;
        }

        uint256 onlyB = _routeOutput(a, b, dx, 0);
        if (onlyB > totalOut) {
            splitA = 0;
            totalOut = onlyB;
        }
    }

    /// @notice Split one exact-input swap across two constant-product pools.
    /// The optimum is where their marginal outputs equalize.
    function bestSplitTwoPools(
        uint256 xA,
        uint256 yA,
        uint256 xB,
        uint256 yB,
        uint256 dx,
        uint256 feeABps,
        uint256 feeBBps
    ) internal pure returns (uint256 splitA, uint256 totalOut) {
        require(
            xA > 0 && yA > 0 && xB > 0 && yB > 0 &&
            dx > 0 && feeABps < BPS && feeBBps < BPS,
            "bad route"
        );
        return _bestSplit(
            Pool({x: xA, y: yA, feeBps: feeABps}),
            Pool({x: xB, y: yB, feeBps: feeBBps}),
            dx
        );
    }}
