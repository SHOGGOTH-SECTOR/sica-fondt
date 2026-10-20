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

    struct ArbitrageResult {
        bool zeroForOne;
        uint256 amountIn;
        uint256 amountOut;
        uint256 profitQuote;
        uint256 postPriceWad;
    }

    struct SandwichResult {
        uint256 frontOut;
        uint256 victimOut;
        uint256 backOut;
        uint256 profitToken0;
    }

    struct ArbitrageResult {
        bool zeroForOne;
        uint256 amountIn;
        uint256 amountOut;
        int256 profitQuote;
        uint256 postPriceWad;
    }

    struct SandwichResult {
        uint256 frontOut;
        uint256 victimOut;
        uint256 backOut;
        int256 profitToken0;
    }

    enum PredictionType {
        ImpermanentLoss,
        PoolReturn,
        OptimalRange,
        SlippageEstimate,
        LpWithdrawalThreshold
    }

    struct PoolState {
        uint256 x;
        uint256 y;
        uint256 feeBps;
        uint256 volumeWad;
        uint256 tvlWad;
        uint256 priceRatioWad;
        uint256 externalPriceWad;
        uint256 volatilityWad;
        uint256 tradeSizeWad;
        uint256 uncertaintyBps;
        uint256 horizonSeconds;
    }

    struct BoundedPrediction {
        int256 value;
        int256 lower;
        int256 upper;
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


    function lpShouldRebalance(
        uint256 feeIncomeWad,
        uint256 rebalanceCostWad,
        uint256 ratioWad
    ) internal pure returns (bool) {
        int256 il = impermanentLossWad(ratioWad);
        uint256 loss = il < 0 ? uint256(-il) : 0;
        return loss > feeIncomeWad + rebalanceCostWad;
    }

    function jitFeeIncomeWad(
        uint256 tradeAmount,
        uint256 feeBps,
        uint256 jitLiquidity,
        uint256 totalLiquidity
    ) internal pure returns (uint256) {
        require(feeBps < BPS, "bad fee");
        require(totalLiquidity > 0, "no liquidity");
        require(jitLiquidity <= totalLiquidity, "jit share");
        uint256 totalFee = tradeAmount * feeBps / BPS;
        return totalFee * jitLiquidity / totalLiquidity;
    }

    function jitShouldProvide(
        uint256 tradeAmount,
        uint256 feeBps,
        uint256 jitLiquidity,
        uint256 totalLiquidity,
        uint256 placementCost
    ) internal pure returns (bool) {
        return jitFeeIncomeWad(
            tradeAmount,
            feeBps,
            jitLiquidity,
            totalLiquidity
        ) > placementCost;
    }


    function lpShouldRebalance(
        uint256 feeIncomeWad,
        uint256 rebalanceCostWad,
        uint256 ratioWad
    ) internal pure returns (bool) {
        int256 il = impermanentLossWad(ratioWad);
        uint256 loss = il < 0 ? uint256(-il) : 0;
        return loss > feeIncomeWad + rebalanceCostWad;
    }

    function jitFeeIncomeWad(
        uint256 volumeWad,
        uint256 feeBps,
        uint256 ownLiquidity,
        uint256 totalLiquidity
    ) internal pure returns (uint256) {
        require(feeBps < BPS, "fee");
        require(totalLiquidity > 0 && ownLiquidity <= totalLiquidity, "liquidity");
        uint256 grossFees = volumeWad * feeBps / BPS;
        return grossFees * ownLiquidity / totalLiquidity;
    }

    function jitShouldProvide(
        uint256 volumeWad,
        uint256 feeBps,
        uint256 ownLiquidity,
        uint256 totalLiquidity,
        uint256 entryExitCostWad
    ) internal pure returns (bool) {
        return jitFeeIncomeWad(
            volumeWad, feeBps, ownLiquidity, totalLiquidity
        ) > entryExitCostWad;
    }


    function feeYieldWad(
        uint256 volumeWad,
        uint256 feeBps,
        uint256 tvlWad
    ) internal pure returns (uint256) {
        require(tvlWad > 0 && feeBps < BPS, "yield");
        uint256 fees = volumeWad * feeBps / BPS;
        return fees * WAD / tvlWad;
    }

    function withdrawalUpperRatioWad(
        uint256 feeIncomeWad
    ) internal pure returns (uint256) {
        require(feeIncomeWad < WAD, "fee income");
        if (feeIncomeWad == 0) return WAD;

        uint256 retained = WAD - feeIncomeWad;
        uint256 discriminant =
            WAD * WAD - retained * retained;
        uint256 root = sqrt(discriminant);
        uint256 sqrtRatioWad =
            (WAD + root) * WAD / retained;
        return sqrtRatioWad * sqrtRatioWad / WAD;
    }

    function _int(uint256 x) private pure returns (int256) {
        require(x <= uint256(type(int256).max), "int overflow");
        return int256(x);
    }

    function _min3(
        int256 a, int256 b, int256 c0
    ) private pure returns (int256) {
        int256 m = a < b ? a : b;
        return m < c0 ? m : c0;
    }

    function _max3(
        int256 a, int256 b, int256 c0
    ) private pure returns (int256) {
        int256 m = a > b ? a : b;
        return m > c0 ? m : c0;
    }

    function _scaledByUncertainty(
        uint256 value,
        uint256 uncertaintyBps,
        bool upper
    ) private pure returns (uint256) {
        require(uncertaintyBps < BPS, "uncertainty");
        uint256 factor = upper
            ? BPS + uncertaintyBps
            : BPS - uncertaintyBps;
        return value * factor / BPS;
    }

    function _ilPrediction(
        PoolState memory s
    ) private pure returns (BoundedPrediction memory p) {
        uint256 loRatio = _scaledByUncertainty(
            s.priceRatioWad, s.uncertaintyBps, false
        );
        uint256 hiRatio = _scaledByUncertainty(
            s.priceRatioWad, s.uncertaintyBps, true
        );
        int256 a = impermanentLossWad(loRatio);
        int256 b = impermanentLossWad(s.priceRatioWad);
        int256 c0 = impermanentLossWad(hiRatio);
        p.value = b;
        p.lower = _min3(a, b, c0);
        p.upper = _max3(a, b, c0);
        if (loRatio <= WAD && hiRatio >= WAD) {
            p.upper = 0;
        }
    }

    function _poolReturnPrediction(
        PoolState memory s
    ) private pure returns (BoundedPrediction memory p) {
        BoundedPrediction memory il = _ilPrediction(s);
        uint256 lowVolume = _scaledByUncertainty(
            s.volumeWad, s.uncertaintyBps, false
        );
        uint256 highVolume = _scaledByUncertainty(
            s.volumeWad, s.uncertaintyBps, true
        );
        int256 fee = _int(
            feeYieldWad(s.volumeWad, s.feeBps, s.tvlWad)
        );
        int256 lowFee = _int(
            feeYieldWad(lowVolume, s.feeBps, s.tvlWad)
        );
        int256 highFee = _int(
            feeYieldWad(highVolume, s.feeBps, s.tvlWad)
        );
        p.value = fee + il.value;
        p.lower = lowFee + il.lower;
        p.upper = highFee + il.upper;
    }

    function _optimalRangePrediction(
        PoolState memory s
    ) private pure returns (BoundedPrediction memory p) {
        require(
            s.externalPriceWad > 0 && s.horizonSeconds > 0,
            "range"
        );
        uint256 yearSeconds = 365 days;
        uint256 fractionWad =
            s.horizonSeconds * WAD / yearSeconds;
        uint256 sqrtTimeWad = sqrt(fractionWad * WAD);
        uint256 widthWad =
            2 * s.volatilityWad * sqrtTimeWad / WAD;
        if (widthWad > 9e17) widthWad = 9e17;

        p.value = _int(s.externalPriceWad);
        p.lower = _int(
            s.externalPriceWad * (WAD - widthWad) / WAD
        );
        p.upper = _int(
            s.externalPriceWad * (WAD + widthWad) / WAD
        );
    }

    function _slippagePrediction(
        PoolState memory s
    ) private pure returns (BoundedPrediction memory p) {
        uint256 lowTrade = _scaledByUncertainty(
            s.tradeSizeWad, s.uncertaintyBps, false
        );
        uint256 highTrade = _scaledByUncertainty(
            s.tradeSizeWad, s.uncertaintyBps, true
        );
        p.value = _int(
            slippageWad(s.x, s.y, s.tradeSizeWad, s.feeBps)
        );
        p.lower = _int(
            slippageWad(s.x, s.y, lowTrade, s.feeBps)
        );
        p.upper = _int(
            slippageWad(s.x, s.y, highTrade, s.feeBps)
        );
    }

    function _thresholdPrediction(
        PoolState memory s
    ) private pure returns (BoundedPrediction memory p) {
        uint256 lowVolume = _scaledByUncertainty(
            s.volumeWad, s.uncertaintyBps, false
        );
        uint256 highVolume = _scaledByUncertainty(
            s.volumeWad, s.uncertaintyBps, true
        );
        uint256 fee = feeYieldWad(
            s.volumeWad, s.feeBps, s.tvlWad
        );
        uint256 lowFee = feeYieldWad(
            lowVolume, s.feeBps, s.tvlWad
        );
        uint256 highFee = feeYieldWad(
            highVolume, s.feeBps, s.tvlWad
        );
        if (fee >= WAD) fee = WAD - 1;
        if (lowFee >= WAD) lowFee = WAD - 1;
        if (highFee >= WAD) highFee = WAD - 1;

        p.value = _int(withdrawalUpperRatioWad(fee));
        p.lower = _int(withdrawalUpperRatioWad(lowFee));
        p.upper = _int(withdrawalUpperRatioWad(highFee));
    }

    function predict(
        PredictionType predictionType,
        PoolState memory s
    ) internal pure returns (BoundedPrediction memory) {
        require(
            s.x > 0 && s.y > 0 &&
            s.tvlWad > 0 &&
            s.priceRatioWad > 0 &&
            s.tradeSizeWad > 0 &&
            s.feeBps < BPS &&
            s.uncertaintyBps < BPS,
            "bad state"
        );

        if (predictionType == PredictionType.ImpermanentLoss) {
            return _ilPrediction(s);
        }
        if (predictionType == PredictionType.PoolReturn) {
            return _poolReturnPrediction(s);
        }
        if (predictionType == PredictionType.OptimalRange) {
            return _optimalRangePrediction(s);
        }
        if (predictionType == PredictionType.SlippageEstimate) {
            return _slippagePrediction(s);
        }
        return _thresholdPrediction(s);
    }



    function _optimalInputForMarginal(
        Pool memory pool,
        uint256 targetMarginalWad
    ) private pure returns (uint256) {
        if (_marginalOutWad(
            pool.x, pool.y, 0, pool.feeBps
        ) <= targetMarginalWad) {
            return 0;
        }

        uint256 lo = 0;
        uint256 hi = pool.x;
        for (uint256 i = 0; i < 8; ++i) {
            if (_marginalOutWad(
                pool.x, pool.y, hi, pool.feeBps
            ) <= targetMarginalWad) break;
            require(hi <= type(uint256).max / 2, "arb range");
            hi *= 2;
        }

        for (uint256 i = 0; i < 64 && lo < hi; ++i) {
            uint256 mid = lo + (hi - lo) / 2;
            if (_marginalOutWad(
                pool.x, pool.y, mid, pool.feeBps
            ) > targetMarginalWad) {
                lo = mid + 1;
            } else {
                hi = mid;
            }
        }
        return lo;
    }

    function _signedDifference(
        uint256 positive,
        uint256 negative
    ) private pure returns (int256) {
        require(
            positive <= uint256(type(int256).max) &&
            negative <= uint256(type(int256).max),
            "signed overflow"
        );
        return int256(positive) - int256(negative);
    }

    function backrunToPrice(
        uint256 x,
        uint256 y,
        uint256 externalPriceWad,
        uint256 feeBps
    ) internal pure returns (ArbitrageResult memory r) {
        require(
            x > 0 && y > 0 && externalPriceWad > 0 && feeBps < BPS,
            "bad arb"
        );
        uint256 poolPriceWad = y * WAD / x;
        if (poolPriceWad == externalPriceWad) {
            r.postPriceWad = poolPriceWad;
            return r;
        }

        if (poolPriceWad > externalPriceWad) {
            r.zeroForOne = true;
            Pool memory pool = Pool({x: x, y: y, feeBps: feeBps});
            r.amountIn = _optimalInputForMarginal(
                pool, externalPriceWad
            );
            if (r.amountIn == 0) {
                r.postPriceWad = poolPriceWad;
                return r;
            }
            r.amountOut = amountOut(x, y, r.amountIn, feeBps);
            uint256 newX = x + r.amountIn;
            uint256 newY = y - r.amountOut;
            r.postPriceWad = newY * WAD / newX;
            uint256 externalCost = r.amountIn * externalPriceWad / WAD;
            r.profitQuote = _signedDifference(
                r.amountOut, externalCost
            );
            return r;
        }

        uint256 reciprocalPriceWad = WAD * WAD / externalPriceWad;
        Pool memory reversePool = Pool({x: y, y: x, feeBps: feeBps});
        r.amountIn = _optimalInputForMarginal(
            reversePool, reciprocalPriceWad
        );
        if (r.amountIn == 0) {
            r.postPriceWad = poolPriceWad;
            return r;
        }
        r.amountOut = amountOut(y, x, r.amountIn, feeBps);
        uint256 newY2 = y + r.amountIn;
        uint256 newX2 = x - r.amountOut;
        r.postPriceWad = newY2 * WAD / newX2;
        uint256 externalValue = r.amountOut * externalPriceWad / WAD;
        r.profitQuote = _signedDifference(
            externalValue, r.amountIn
        );
    }

    function simulateSandwich(
        uint256 x,
        uint256 y,
        uint256 victimDx,
        uint256 attackerDx,
        uint256 feeBps
    ) internal pure returns (SandwichResult memory r) {
        require(
            x > 0 && y > 0 && victimDx > 0 &&
            attackerDx > 0 && feeBps < BPS,
            "bad sandwich"
        );

        r.frontOut = amountOut(x, y, attackerDx, feeBps);
        uint256 x1 = x + attackerDx;
        uint256 y1 = y - r.frontOut;

        r.victimOut = amountOut(x1, y1, victimDx, feeBps);
        uint256 x2 = x1 + victimDx;
        uint256 y2 = y1 - r.victimOut;

        r.backOut = amountOut(
            y2, x2, r.frontOut, feeBps
        );
        r.profitToken0 = _signedDifference(
            r.backOut, attackerDx
        );
    }

    function _spotPriceWad(uint256 x, uint256 y)
        private pure returns (uint256)
    {
        require(x > 0 && y > 0, "bad reserves");
        return y * WAD / x;
    }

    function _arbCandidate(
        uint256 x,
        uint256 y,
        uint256 amountIn,
        uint256 externalPriceWad,
        uint256 feeBps,
        bool zeroForOne
    ) private pure returns (ArbitrageResult memory r) {
        r.zeroForOne = zeroForOne;
        r.amountIn = amountIn;

        if (amountIn == 0) {
            r.postPriceWad = _spotPriceWad(x, y);
            return r;
        }

        if (zeroForOne) {
            r.amountOut = amountOut(x, y, amountIn, feeBps);
            uint256 postX = x + amountIn;
            uint256 postY = y - r.amountOut;
            r.postPriceWad = _spotPriceWad(postX, postY);
            uint256 externalCost = amountIn * externalPriceWad / WAD;
            if (r.amountOut > externalCost) {
                r.profitQuote = r.amountOut - externalCost;
            }
        } else {
            r.amountOut = amountOut(y, x, amountIn, feeBps);
            uint256 postY = y + amountIn;
            uint256 postX = x - r.amountOut;
            r.postPriceWad = _spotPriceWad(postX, postY);
            uint256 externalValue = r.amountOut * externalPriceWad / WAD;
            if (externalValue > amountIn) {
                r.profitQuote = externalValue - amountIn;
            }
        }
    }

    function _priceError(uint256 a, uint256 b)
        private pure returns (uint256)
    {
        return a > b ? a - b : b - a;
    }

    function backrunToPrice(
        uint256 x,
        uint256 y,
        uint256 externalPriceWad,
        uint256 feeBps
    ) internal pure returns (ArbitrageResult memory best) {
        require(
            x > 0 && y > 0 &&
            externalPriceWad > 0 &&
            feeBps < BPS,
            "bad arb"
        );

        uint256 current = _spotPriceWad(x, y);
        if (current == externalPriceWad) {
            best.postPriceWad = current;
            return best;
        }

        bool zeroForOne = current > externalPriceWad;
        uint256 base = zeroForOne ? x : y;
        uint256 lo = 0;
        uint256 hi = base;

        // Expand until the post-trade price crosses the reference price.
        for (uint256 i = 0; i < 24; ++i) {
            ArbitrageResult memory probe = _arbCandidate(
                x, y, hi, externalPriceWad, feeBps, zeroForOne
            );
            bool crossed = zeroForOne
                ? probe.postPriceWad <= externalPriceWad
                : probe.postPriceWad >= externalPriceWad;
            if (crossed) break;
            require(hi <= type(uint256).max / 2, "arb overflow");
            hi *= 2;
        }

        for (uint256 i = 0; i < 64 && lo < hi; ++i) {
            uint256 mid = lo + (hi - lo) / 2;
            ArbitrageResult memory probe = _arbCandidate(
                x, y, mid, externalPriceWad, feeBps, zeroForOne
            );
            if (zeroForOne) {
                if (probe.postPriceWad > externalPriceWad) {
                    lo = mid + 1;
                } else {
                    hi = mid;
                }
            } else {
                if (probe.postPriceWad < externalPriceWad) {
                    lo = mid + 1;
                } else {
                    hi = mid;
                }
            }
        }

        best = _arbCandidate(
            x, y, lo, externalPriceWad, feeBps, zeroForOne
        );
        if (lo > 0) {
            ArbitrageResult memory alt = _arbCandidate(
                x, y, lo - 1, externalPriceWad, feeBps, zeroForOne
            );
            if (
                _priceError(alt.postPriceWad, externalPriceWad) <
                _priceError(best.postPriceWad, externalPriceWad)
            ) {
                best = alt;
            }
        }
    }

    function simulateSandwich(
        uint256 x,
        uint256 y,
        uint256 victimDx,
        uint256 attackerFrontDx,
        uint256 feeBps
    ) internal pure returns (SandwichResult memory s) {
        require(
            x > 0 && y > 0 &&
            victimDx > 0 && attackerFrontDx > 0 &&
            feeBps < BPS,
            "bad sandwich"
        );

        s.frontOut = amountOut(
            x, y, attackerFrontDx, feeBps
        );
        x += attackerFrontDx;
        y -= s.frontOut;

        s.victimOut = amountOut(
            x, y, victimDx, feeBps
        );
        x += victimDx;
        y -= s.victimOut;

        s.backOut = amountOut(
            y, x, s.frontOut, feeBps
        );
        if (s.backOut > attackerFrontDx) {
            s.profitToken0 = s.backOut - attackerFrontDx;
        }
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
