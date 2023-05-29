// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./libraries/UniswapLibrary.sol";

contract UniswapSimplePriceOracle {
    address uniswapFactory;

    constructor(address _uniswapFactory) {
        uniswapFactory = _uniswapFactory;
    }

    function getPriceFor(address tokenA, address tokenB, uint256 tokenAAmt) public view returns (uint256 dust) {
        (uint reserve0, uint reserve1) = UniswapV2Library.getReserves(uniswapFactory, tokenA, tokenB);
        dust = UniswapV2Library.getAmountOut(tokenAAmt, reserve0, reserve1);
    }
}