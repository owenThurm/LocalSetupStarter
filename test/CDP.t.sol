// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CDP} from "../src/CDP.sol";
import {Oracle} from "../src/Oracle.sol";
import {MockAggregatorV3} from "./Mock/MockAggregatorV3.sol";
import {MockERC20} from "./Mock/MockERC20.sol";
import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "forge-std/Test.sol";

contract CounterTest is Test {
    CDP public cdp;
    Oracle public oracle;
    MockAggregatorV3 public usdcFeed;
    MockAggregatorV3 public wethFeed;

    MockERC20 public USDC;
    MockERC20 public WETH;

    uint8 public constant FEED_DECIMALS = 8;
    uint256 public constant HEARTBEAT = 3600; // 1 hour

    function setUp() public {
        oracle = new Oracle();

        // Deploy mock ERC20s
        USDC = new MockERC20("USDC", "USDC", 6);
        WETH = new MockERC20("WETH", "WETH", 18);

        // Set up aggregators

        // deploy mockAggregator for WETH
        wethFeed = new MockAggregatorV3(
            FEED_DECIMALS, //decimals
            "WETH", //description
            1, //version
            0, //roundId
            int256(5_000 * 10**FEED_DECIMALS), //answer
            0, //startedAt
            block.timestamp, //updatedAt
            0 //answeredInRound
        );

        // deploy mockAggregator for USDC
        usdcFeed = new MockAggregatorV3(
            FEED_DECIMALS, //decimals
            "USDC", //description
            1, //version
            0, //roundId
            int256(1 * 10**FEED_DECIMALS), //answer
            0, //startedAt
            block.timestamp, //updatedAt
            0 //answeredInRound
        );

        oracle.updatePricefeedConfig(
            address(WETH), 
            AggregatorV3Interface(wethFeed), 
            HEARTBEAT
        );

        oracle.updatePricefeedConfig(
            address(USDC), 
            AggregatorV3Interface(usdcFeed), 
            HEARTBEAT
        );

        cdp = new CDP(oracle);

        // Set Decimals Multiplier for USDC
        // 1e8 * 1e6 = 1e14
        // Need 1e18, therefore net multiplier must be 1e4
        // Need 1e34
        cdp.setTokenDecimalsMultiplier(address(USDC), 1e34);

        // Set Decimals Multiplier for ETH
        // 1e8 * 1e18 = 1e26
        // Need 1e18, therefore net multiplier must be 1e-8
        // Need 1e22
        cdp.setTokenDecimalsMultiplier(address(WETH), 1e22);
    }

    function test_GetEthPrice() public {
        // Get the initial price for ETH
        uint256 ethPrice = oracle.getTokenPrice(address(WETH));

        assertTrue(ethPrice == 5_000 * 1e8);

        // Set price for ETH
        wethFeed.setPrice(4_000 * 1e8);

        // Get new price for ETH
        ethPrice = oracle.getTokenPrice(address(WETH));

        assertTrue(ethPrice == 4_000 * 1e8);
    }

    function test_GetUsdcPrice() public {
        // Get the initial price for USDC
        uint256 usdcPrice = oracle.getTokenPrice(address(USDC));

        assertTrue(usdcPrice == 1 * 1e8);

        // Set price for USDC
        usdcFeed.setPrice(12 * 1e7); // $1.2

        // Get new price for USDC
        usdcPrice = oracle.getTokenPrice(address(USDC));

        assertTrue(usdcPrice == 12 * 1e7);
    }

    function test_GetUsdcDollarValue() public {
        uint256 usdcValue = cdp.getTokensDollarValue(address(USDC), 1e6);

        // 1 USDC should be $1 (1e18 representation)
        assertTrue(usdcValue == 1e18);

        usdcValue = cdp.getTokensDollarValue(address(USDC), 50e6);

        // 50 USDC should be $50 (1e18 representation)
        assertTrue(usdcValue == 50e18);
    }

    function test_GetWethDollarValue() public {
        uint256 wethValue = cdp.getTokensDollarValue(address(WETH), 1e18);

        // 1 WETH should be $5,000 (1e18 representation)
        assertTrue(wethValue == 5_000e18);

        wethValue = cdp.getTokensDollarValue(address(WETH), 10e18);

        // 10 WETH should be $50,000 (1e18 representation)
        assertTrue(wethValue == 50_000e18);
    }

}
