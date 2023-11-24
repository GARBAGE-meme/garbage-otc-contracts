// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/GarbageToken.sol";

contract GarbageTokenTestnet is GarbageToken {
    IERC20 public constant WETHT = IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    constructor(uint256 _initialSupply, address _owner) GarbageToken(_initialSupply, _owner){}

    function burnTestnet(address _user, uint256 _amount) external {
        _burn(_user, _amount);
    }

    function mintTestnet(address _user, uint256 _amount) external {
        _mint(_user, _amount);
    }

    function createPairAndAddLiquidityTestnet() public onlyOwner {
        if (listingBlock != 0) revert AlreadyListed();
        uint256 tokenToList = balanceOf(address(this));
        uint256 wethToList = WETHT.balanceOf(address(this));

        address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _approve(address(this), address(uniswapV2Router), tokenToList);
        WETHT.approve(address(uniswapV2Router), wethToList);

        uniswapV2Router.addLiquidity(address(this), address(WETHT), tokenToList, wethToList, tokenToList, wethToList, owner(), block.timestamp);

        listingBlock = block.number;
    }
}
