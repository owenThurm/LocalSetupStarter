// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Oracle} from "./Oracle.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

import "forge-std/Test.sol";

contract CDP is Ownable2Step {

    Oracle public oracle;
    uint256 public constant PRECISION_DIVISOR = 1e30;

    mapping(address => uint256) tokenDecimalsMultiplier;

    constructor(Oracle _oracle) Ownable(msg.sender) {
        oracle = _oracle;
    }

    function setTokenDecimalsMultiplier(address token, uint256 multiplier) external onlyOwner {
        tokenDecimalsMultiplier[token] = multiplier;
    }

    function getTokensDollarValue(address token, uint256 tokenAmount) external returns (uint256) {
        uint256 tokenPrice = oracle.getTokenPrice(token);

        return tokenAmount * tokenPrice * tokenDecimalsMultiplier[token] / PRECISION_DIVISOR;
    }

}
