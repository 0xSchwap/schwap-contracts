// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "forge-std/console.sol";

import "../src/UniswapSimplePriceOracle.sol";
import "../src/SchwapMarket.sol";
import "../src/SupSchwapMarket.sol";
import "../src/SCH.sol";
import "../src/veSCH.sol";

import "@uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/IWETH9.sol";

contract Deploy is Script, IERC721Receiver {
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    address _positionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address _factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address _factoryV3 = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 public constant poolFee = 10000;

    INonfungiblePositionManager public nonFungiblePositionManager = INonfungiblePositionManager(_positionManager);
    IUniswapV3Factory public factoryV3 = IUniswapV3Factory(_factoryV3);
    IWETH9 public __weth = IWETH9(_weth);
    IERC20 public __sch;

    address _oracle;
    address _mkt;
    address _sup;
    address _sch;
    address _vesch;
    address _pool;

    uint256 public amount0ToMint;
    uint256 public amount1ToMint;
    uint160 public sqrtPriceX96;

    function setUp() public {
        amount0ToMint = 1_000_000 * (10 ** 18);
        amount1ToMint = 500 ether;
        //BigInt((2 ** 96) / Math.sqrt(parseFloat(0.01) * 1000000000)).toString();
        sqrtPriceX96 = 25054144837504793613172736;
    }

    function run() public {
        vm.startBroadcast();

        UniswapSimplePriceOracle oracle = new UniswapSimplePriceOracle(_factory);
        _oracle = address(oracle);

        SchwapMarket mkt = new SchwapMarket(_weth, (10 ** 15), _oracle);
        _mkt = address(mkt);

        SupSchwapMarket sup = new SupSchwapMarket();
        _sup = address(sup);

        SCH sch = new SCH();
        _sch = address(sch);
        __sch = IERC20(_sch);

        veSCH vesch = new veSCH();
        _vesch = address(vesch);

        vesch.initialize(address(sch));

        __sch.approve(address(nonFungiblePositionManager), type(uint256).max);
        __weth.approve(address(nonFungiblePositionManager), type(uint256).max);

        __weth.deposit{value: 500 ether}();
        console.log("amount0ToMint:    ", amount0ToMint);
        console.log("amount1ToMint:    ", amount1ToMint);
        console.log("amount0Balance:   ", __sch.balanceOf(msg.sender));
        console.log("amount1Balance:   ", __weth.balanceOf(msg.sender));
        console.log("ETH balance:      ", (msg.sender).balance);

        //_pool = factoryV3.createPool(_sch, _weth, poolFee);
        //IUniswapV3Pool(_pool).initialize(sqrtPriceX96);
        _pool = nonFungiblePositionManager.createAndInitializePoolIfNecessary(_sch, _weth, poolFee, sqrtPriceX96);
        (, int24 _currentTick, , , , , ) = IUniswapV3Pool(_pool).slot0();
        console.logInt(_currentTick);
        /*
        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: _sch,
                token1: _weth,
                fee: poolFee,
                tickLower: MIN_TICK,
                tickUpper: MAX_TICK,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 0,
                amount1Min: 0,
                recipient: msg.sender,
                deadline: block.timestamp + 86400
            });

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = nonFungiblePositionManager.mint(params);
        */

        _logDeploymentAddresses();

        vm.stopBroadcast();
    }

    function _logDeploymentAddresses() private view {
        console.log("UniswapSimplePriceOracle deployed to:    ", _oracle);
        console.log("SchwapMarket deployed to:                ", _mkt);
        console.log("SupSchwapMarket deployed to:             ", _sup);
        console.log("SCH deployed to:                         ", _sch);
        console.log("veSCH deployed to:                       ", _vesch);
        console.log("Pool deployed to:                        ", _pool);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
