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
}
