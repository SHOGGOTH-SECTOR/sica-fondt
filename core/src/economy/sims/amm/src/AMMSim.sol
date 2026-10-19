// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

library AMMSim {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant BPS = 10_000;

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
}
