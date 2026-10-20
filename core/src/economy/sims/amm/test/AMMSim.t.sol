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

}
