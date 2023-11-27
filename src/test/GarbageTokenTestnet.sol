// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/GarbageToken.sol";

contract GarbageTokenTestnet is GarbageToken {
    IERC20 public constant WETHT = IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    constructor(uint256 _initialSupply, address _owner) GarbageToken(_initialSupply, _owner){}

    /// forge-config: default.fuzz.runs = 100
    function burnTestnet(address _user, uint256 _amount) external {
        _burn(_user, _amount);
    }

    function mintTestnet(address _user, uint256 _amount) external {
        _mint(_user, _amount);
    }

    function createPairTestnet() external onlyOwner {
        if (address(uniswapPair) != address(0)) revert PairAlreadyCreated();
        uniswapPair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), address(WETHT))
        );
    }

    function provideLiquidityTestnet(bool shouldBlock) external onlyOwner {
        uint256 tokenToList = balanceOf(address(this));
        uint256 wethToList = WETHT.balanceOf(address(this));

        _approve(address(this), address(uniswapV2Router), tokenToList);
        WETHT.approve(address(uniswapV2Router), wethToList);

        uniswapV2Router.addLiquidity(
            address(this),
            address(WETHT),
            tokenToList,
            wethToList,
            0,
            0,
            owner(),
            block.timestamp);

        (uint112 reserve0, uint112 reserve1,) = uniswapPair.getReserves();

        holdLimit = uint256(uniswapPair.token0() == address(this) ? reserve0 : reserve1) / 100;

        if (shouldBlock) {
            listingBlock = block.number;
            listingTime = block.timestamp;
        }
    }
}
