// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import "../src/AMMSim.sol";
contract AMMSimTest {
    function testInvariantDirection() public pure {
        uint256 x=1000e18; uint256 y=1000e18; uint256 dx=10e18;
        uint256 dy=AMMSim.amountOut(x,y,dx,30);
        require(dy>0 && dy<y, "swap");
        uint256 dxEff=dx*9970/10000;
        require((x+dxEff)*(y-dy) >= x*y, "k lower by rounding");
    }
    function testImpermanentLossKnownRatio() public pure {
        int256 il=AMMSim.impermanentLossWad(4e18);
        int256 expected=-2e17;
        int256 d=il-expected; if (d<0) d=-d;
        require(d < 1e10, "IL formula");
    }
    function testSlippageGrowsWithSize() public pure {
        uint256 a=AMMSim.slippageWad(1000e18,1000e18,1e18,30);
        uint256 b=AMMSim.slippageWad(1000e18,1000e18,100e18,30);
        require(b>a, "slippage");
    }
    function testWithdrawalDerivedFromIL() public pure {
        require(AMMSim.lpShouldWithdraw(1e16,4e18), "withdraw");
        require(!AMMSim.lpShouldWithdraw(3e17,4e18), "stay");
    }
    function testConcentratedLiquidityAmountsAtMidPrice() public pure {
        (uint256 amount0,uint256 amount1)=AMMSim.concentratedAmounts(
            600e18, 1e18, 2e18, 3e18
        );
        require(amount0 == 100e18, "amount0");
        require(amount1 == 600e18, "amount1");
    }

    function testConcentratedLiquidityBecomesOneSidedOutsideRange() public pure {
        (uint256 below0,uint256 below1)=AMMSim.concentratedAmounts(
            600e18, 1e18, 5e17, 3e18
        );
        require(below0 == 400e18 && below1 == 0, "below");
        (uint256 above0,uint256 above1)=AMMSim.concentratedAmounts(
            600e18, 1e18, 4e18, 3e18
        );
        require(above0 == 0 && above1 == 1200e18, "above");
    }

    function testSplitRoutingUsesBothPoolsAndImprovesOutput() public pure {
        uint256 dx=100e18;
        uint256 singleA=AMMSim.amountOut(1000e18,1000e18,dx,30);
        uint256 singleB=AMMSim.amountOut(500e18,500e18,dx,30);
        (uint256 splitA,uint256 totalOut)=AMMSim.bestSplitTwoPools(
            1000e18,1000e18,500e18,500e18,dx,30,30
        );
        require(splitA > 0 && splitA < dx, "must split");
        require(splitA > dx/2, "deeper pool gets more");
        require(totalOut > singleA && totalOut > singleB, "split improves");
    }

    function testActiveLpRebalanceComparesIlFeesAndCost() public pure {
        require(
            AMMSim.lpShouldRebalance(1e16, 5e15, 4e18),
            "rebalance when IL dominates"
        );
        require(
            !AMMSim.lpShouldRebalance(25e16, 5e15, 4e18),
            "stay when fees dominate"
        );
    }

    function testJitLiquidityRequiresPositiveNetFeeShare() public pure {
        uint256 income=AMMSim.jitFeeIncomeWad(
            1000e18, 30, 100e18, 1000e18
        );
        require(income == 3e17, "fee share");
        require(
            AMMSim.jitShouldProvide(
                1000e18, 30, 100e18, 1000e18, 2e17
            ),
            "profitable JIT"
        );
        require(
            !AMMSim.jitShouldProvide(
                1000e18, 30, 100e18, 1000e18, 4e17
            ),
            "costly JIT"
        );
    }

    function testBackrunMovesPoolTowardExternalPrice() public pure {
        AMMSim.ArbitrageResult memory a=AMMSim.backrunToPrice(
            1000e18, 2000e18, 15e17, 30
        );
        require(a.amountIn > 0 && a.amountOut > 0, "arb size");
        require(a.zeroForOne, "x in");
        require(a.profitQuote > 0, "profitable");
        uint256 pre=2e18;
        uint256 preError=pre > 15e17 ? pre-15e17 : 15e17-pre;
        uint256 postError=a.postPriceWad > 15e17
            ? a.postPriceWad-15e17
            : 15e17-a.postPriceWad;
        require(postError < preError, "price converges");
    }

    function testSandwichSimulationAccountsForBothLegs() public pure {
        AMMSim.SandwichResult memory s=AMMSim.simulateSandwich(
            1000e18, 1000e18, 100e18, 10e18, 30
        );
        require(s.frontOut > 0 && s.victimOut > 0 && s.backOut > 0, "legs");
        require(s.profitToken0 > 0, "positive sandwich");
        require(s.victimOut < AMMSim.amountOut(1000e18,1000e18,100e18,30), "victim worsens");
    }

    function _basePoolState() private pure returns (AMMSim.PoolState memory s) {
        s.x=1000e18;
        s.y=1000e18;
        s.feeBps=100;
        s.volumeWad=5000e18;
        s.tvlWad=1000e18;
        s.priceRatioWad=4e18;
        s.externalPriceWad=1e18;
        s.volatilityWad=5e17;
        s.tradeSizeWad=10e18;
        s.uncertaintyBps=500;
        s.horizonSeconds=7 days;
    }

    function testWithdrawalThresholdIsDerivedFromIlFormula() public pure {
        uint256 threshold=AMMSim.withdrawalUpperRatioWad(2e17);
        uint256 d=threshold > 4e18 ? threshold-4e18 : 4e18-threshold;
        require(d < 1e11, "20pct IL threshold");
        int256 il=AMMSim.impermanentLossWad(threshold);
        int256 target=-2e17;
        int256 e=il-target; if (e<0) e=-e;
        require(e < 1e10, "threshold reproduces IL");
    }

    function testPoolReturnCombinesFeesAndImpermanentLoss() public pure {
        AMMSim.PoolState memory s=_basePoolState();
        AMMSim.BoundedPrediction memory p=AMMSim.predict(
            AMMSim.PredictionType.PoolReturn, s
        );
        int256 expected=-15e16;
        int256 d=p.value-expected; if (d<0) d=-d;
        require(d < 1e12, "fees minus IL");
        require(p.lower <= p.value && p.value <= p.upper, "bounded");
    }

    function testOptimalRangeWidensWithVolatility() public pure {
        AMMSim.PoolState memory low=_basePoolState();
        low.priceRatioWad=1e18;
        low.volatilityWad=2e17;
        AMMSim.PoolState memory high=low;
        high.volatilityWad=8e17;
        AMMSim.BoundedPrediction memory a=AMMSim.predict(
            AMMSim.PredictionType.OptimalRange, low
        );
        AMMSim.BoundedPrediction memory b=AMMSim.predict(
            AMMSim.PredictionType.OptimalRange, high
        );
        require(b.upper-b.lower > a.upper-a.lower, "wider at high vol");
        require(a.lower <= a.value && a.value <= a.upper, "a bounded");
        require(b.lower <= b.value && b.value <= b.upper, "b bounded");
    }

    function testAllM3cPredictionKindsAreBounded() public pure {
        AMMSim.PoolState memory s=_basePoolState();
        for (uint256 i=0; i<5; ++i) {
            AMMSim.BoundedPrediction memory p=AMMSim.predict(
                AMMSim.PredictionType(i), s
            );
            require(p.lower <= p.value, "lower");
            require(p.value <= p.upper, "upper");
        }
    }

}
