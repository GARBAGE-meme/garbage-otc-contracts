// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/test/ChainLinkPriceFeedMock.sol";
import "src/GarbageSale.sol";
import "lib/forge-std/src/Test.sol";
import "src/GarbageToken.sol";

contract GarbageSaleHarness is GarbageSale {
    constructor(
        address _priceFeed,
        uint256 _usdPrice,
        uint256 _presaleLimit,
        address _owner
    ) GarbageSale(_priceFeed, _usdPrice, _presaleLimit, _owner) {}

    function setSaleLimitHarness(uint256 _saleLimit) public {
        saleLimit = _saleLimit;
    }
}

interface IUniswapV2RouterWithSwap is IUniswapV2Router02 {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external returns (uint[] memory);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112, uint112, uint32);
}

abstract contract TestHelper is Test {
    ChainLinkPriceFeedMock public priceFeed;
    GarbageSaleHarness public saleContract;
    GarbageToken public tokenContract;

    uint256 public tokenPrice = 20_000;
    uint256 public saleLimit = 50_000_000;

    address public owner = address(12345);

    error ZeroPriceFeedAddress();
    error WrongOracleData();
    error TooLowValue();
    error PerWalletLimitExceeded(uint256 remainingLimit);
    error SaleLimitExceeded(uint256 remainingLimit);
    error NotEnoughEthOnContract();
    error EthSendingFailed();

    error AlreadyListed();
    error TransfersBlocked();

    error OwnableUnauthorizedAccount(address account);

    function setUp() public virtual {
        priceFeed = new ChainLinkPriceFeedMock();
        vm.warp(1 days);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        emit log_string("getAmountOut");
        emit log_uint(amountIn);
        emit log_uint(reserveIn);
        emit log_uint(reserveOut);
        uint amountInWithFee = amountIn * 997;
        emit log_uint(amountInWithFee);
        uint numerator = amountInWithFee * reserveOut;
        emit log_uint(numerator);
        uint denominator = reserveIn * 1000 + amountInWithFee;
        emit log_uint(denominator);
        amountOut = numerator / denominator;
        emit log_uint(amountOut);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        emit log_string("getAmountsOut");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        emit log_uint(amounts[0]);
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            emit log_uint(amounts[i]);
        }
    }

    function getReserves(address factory, address tokenA, address tokenB) internal returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        emit log_string("getReserves");
        emit log_uint(reserve0);
        emit log_uint(reserve1);
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function pairFor(address factory, address tokenA, address tokenB) internal returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
        )))));
    }

    function sortTokens(address tokenA, address tokenB) internal returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
}
