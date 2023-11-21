// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {SafeCast} from "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";


contract Oracle is Ownable2Step {
    using SafeCast for int256;

    error InvalidFeedPrice(address, int256);
    error PriceFeedNotUpdated(address, uint256, uint256);

    struct PricefeedConfig {
        AggregatorV3Interface priceFeed;
        uint256 heartBeatDuration;
    }

    constructor () Ownable(msg.sender) {}

    mapping(address => PricefeedConfig) public tokenToConfig;

    function updatePricefeedConfig(
        address token, 
        AggregatorV3Interface priceFeed, 
        uint256 heartBeatDuration
    ) external onlyOwner {
        tokenToConfig[token] = PricefeedConfig(priceFeed, heartBeatDuration);
    }

    function getTokenPrice(address token) external view returns (uint256) {
        PricefeedConfig memory config = tokenToConfig[token];
        (
            /* uint80 roundID */,
            int256 price,
            /* uint256 startedAt */,
            uint256 timestamp,
            /* uint80 answeredInRound */
        ) = config.priceFeed.latestRoundData();

        if (price <= 0) revert InvalidFeedPrice(address(config.priceFeed), price);
        if (block.timestamp - timestamp > config.heartBeatDuration) {
            revert PriceFeedNotUpdated(address(config.priceFeed), timestamp, config.heartBeatDuration);
        }

        return price.toUint256();
    }

}