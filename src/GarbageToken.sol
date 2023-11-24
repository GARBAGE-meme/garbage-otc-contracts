// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "src/interfaces/IUniswapV2Router02.sol";
import "src/interfaces/IUniswapV2Factory.sol";

contract GarbageToken is ERC20, Ownable {
    uint256 private constant antiBotDelay = 5;

    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public listingBlock;

    error AlreadyListed();
    error TransfersBlocked();

    constructor(uint256 _initialSupply, address _owner) ERC20("Garbage Token", "$GARBAGE") Ownable(_owner) {
        _mint(msg.sender, _initialSupply * 10 ** decimals());
    }

    function _update(address from, address to, uint256 value) internal override {
        if (listingBlock != 0
            && block.number <= listingBlock + antiBotDelay) revert TransfersBlocked();
        super._update(from, to, value);
    }

    function createPairAndAddLiquidity() public onlyOwner {
        if (listingBlock != 0) revert AlreadyListed();
        uint256 tokenToList = balanceOf(address(this));
        uint256 wethToList = WETH.balanceOf(address(this));

        IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _approve(address(this), address(uniswapV2Router), tokenToList);
        WETH.approve(address(uniswapV2Router), wethToList);

        uniswapV2Router.addLiquidity(address(this), address(WETH), tokenToList, wethToList, tokenToList, wethToList, owner(), block.timestamp);

        listingBlock = block.number;
    }
}
