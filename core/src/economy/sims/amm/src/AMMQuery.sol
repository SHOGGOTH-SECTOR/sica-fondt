// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./AMMSim.sol";

/// @notice Read-only ABI bridge for M3c. This contract contains no storage,
/// transfer, approval, swap execution, or privileged method. It exists so the
/// Tcl coordinator can evaluate the Solidity-native simulator with eth_call.
contract AMMQuery {
    function _query(
        uint8 predictionType,
        uint256[11] calldata raw
    ) private pure returns (AMMSim.BoundedPrediction memory p) {
        require(predictionType < 5, "prediction type");
        AMMSim.PoolState memory s = AMMSim.PoolState({
            x: raw[0],
            y: raw[1],
            feeBps: raw[2],
            volumeWad: raw[3],
            tvlWad: raw[4],
            priceRatioWad: raw[5],
            externalPriceWad: raw[6],
            volatilityWad: raw[7],
            tradeSizeWad: raw[8],
            uncertaintyBps: raw[9],
            horizonSeconds: raw[10]
        });
        return AMMSim.predict(AMMSim.PredictionType(predictionType), s);
    }

    function queryValue(
        uint8 predictionType,
        uint256[11] calldata raw
    ) external pure returns (int256) {
        return _query(predictionType, raw).value;
    }

    function queryLower(
        uint8 predictionType,
        uint256[11] calldata raw
    ) external pure returns (int256) {
        return _query(predictionType, raw).lower;
    }

    function queryUpper(
        uint8 predictionType,
        uint256[11] calldata raw
    ) external pure returns (int256) {
        return _query(predictionType, raw).upper;
    }
}
