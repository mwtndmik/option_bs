pragma solidity >=0.4.0 <0.7.0;
pragma experimental ABIEncoderV2;
import {AdvancedMath as AM} from "AdvancedMath.sol";

/**
 * @title OptionLib
 * @dev Option Library
 */
contract OptionLib_AdvancedMath {
    /**
     * @dev sqrt(365*86400) * 10^8
     */
    int256 internal constant SQRT_YEAR_E8 = 5615.69229926 * 10**8;

    /**
     * @dev calculate delta
     * @param spotPrice is a oracle price.
     * @param strikePrice Strike price of call option
     * @param rE8 Risk-free intereset rate
     * @param volatilityE8 is a oracle volatility.
     * @param untilMaturity Remaining period of target bond in second
     **/
    function calc_delta(
        int256 spotPrice,
        int256 strikePrice,
        int256 rE8,
        int256 volatilityE8,
        int256 untilMaturity
    ) public pure returns (int256 deltaE8) {
        require(
            spotPrice > 0 && spotPrice < 10**13,
            "oracle price should be between 0 and 10^13"
        );
        require(
            volatilityE8 > 0 && volatilityE8 < 10 * 10**8,
            "oracle volatility should be between 0% and 1000%"
        );
        require(
            untilMaturity > 0 && untilMaturity < 31536000,
            "the bond should not have expired and less than 1 year"
        );
        require(
            strikePrice > 0 && strikePrice < 10**13,
            "strike price should be between 0 and 10^13"
        );

        int256 spotPerStrikeE4 = (spotPrice * 10**4) / strikePrice;
        int256 sigE8 = (volatilityE8 * (AM._sqrt(untilMaturity)) * (10**8)) / SQRT_YEAR_E8;

        int256 logSigE4 = AM._logTaylor(spotPerStrikeE4);
        int256 d1E4 = ((logSigE4 * 10**8) / sigE8) + ((rE8 * AM._sqrt(untilMaturity) * (10**12)) / (volatilityE8 * SQRT_YEAR_E8)) + (sigE8 / (2 * 10**4));
        return AM._calcPnorm(d1E4);
    }


    /**
     * @notice Calculate pure call option price and N(d1) by black-scholes formula.
     * @param spotPrice is a oracle price.
     * @param strikePrice Strike price of call option
     * @param volatilityE8 is a oracle volatility.
     * @param untilMaturity Remaining period of target bond in second
     **/
    function calc_premium_r0(
        int256 spotPrice,
        int256 strikePrice,
        int256 volatilityE8,
        int256 untilMaturity
    ) public pure returns (int256) {
        require(
            spotPrice > 0 && spotPrice < 10**13,
            "oracle price should be between 0 and 10^13"
        );
        require(
            volatilityE8 > 0 && volatilityE8 < 10 * 10**8,
            "oracle volatility should be between 0% and 1000%"
        );
        require(
            untilMaturity > 0 && untilMaturity < 31536000,
            "the bond should not have expired and less than 1 year"
        );
        require(
            strikePrice > 0 && strikePrice < 10**13,
            "strike price should be between 0 and 10^13"
        );

        int256 spotPerStrikeE4 = (spotPrice * 10**4) / strikePrice;
        int256 sigE8 = (volatilityE8 * (AM._sqrt(untilMaturity)) * (10**8)) / SQRT_YEAR_E8;

        int256 logSigE4 = AM._logTaylor(spotPerStrikeE4);
        int256 d1E4 = ((logSigE4 * 10**8) / sigE8) + (sigE8 / (2 * 10**4));
        int256 nd1E8 = AM._calcPnorm(d1E4);

        int256 d2E4 = d1E4 - (sigE8 / 10**4);
        int256 nd2E8 = AM._calcPnorm(d2E4);
        return (spotPrice * nd1E8 - strikePrice * nd2E8) / 10**8;
    }
}