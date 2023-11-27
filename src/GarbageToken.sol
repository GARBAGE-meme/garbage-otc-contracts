// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "src/interfaces/IUniswapV2Router02.sol";
import "src/interfaces/IUniswapV2Factory.sol";
import "src/interfaces/IUniswapV2Pair.sol";

contract GarbageToken is ERC20, Ownable {
    uint256 private constant antiBotDelay = 5;

    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public listingBlock;
    uint256 public listingTime;
    uint256 public holdLimit;
    uint256 public holdLimitDuration = 1 weeks;
    IUniswapV2Pair public uniswapPair;

    error PairAlreadyCreated();
    error PairNotCreated();
    error TransfersBlocked();
    error HoldLimitation();

    constructor(uint256 _initialSupply, address _owner) ERC20("Garbage Token", "$GARBAGE") Ownable(_owner) {
        _mint(msg.sender, _initialSupply * 10 ** decimals());
    }

    function setHoldLimit(uint256 _newHoldLimit) external onlyOwner {
        holdLimit = _newHoldLimit;
    }

    function _update(address from, address to, uint256 value) internal override {
        if (listingBlock != 0
            && block.number <= listingBlock + antiBotDelay) revert TransfersBlocked();
        if (listingBlock != 0
            && block.number <= listingBlock + holdLimitDuration
            && balanceOf(to) + value >= holdLimit
            && to != address(uniswapPair)
            && to != owner()
            && to != address(this)
        ) {
            revert HoldLimitation();
        }
        super._update(from, to, value);
    }

    function createPair() external onlyOwner {
        if (address(uniswapPair) != address(0)) revert PairAlreadyCreated();
        uniswapPair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), address(WETH))
        );
    }

    function provideLiquidity(bool shouldBlock) external onlyOwner {
        if (address(uniswapPair) == address(0)) revert PairNotCreated();
        uint256 tokenToList = balanceOf(address(this));
        uint256 wethToList = WETH.balanceOf(address(this));

        _approve(address(this), address(uniswapV2Router), tokenToList);
        WETH.approve(address(uniswapV2Router), wethToList);

        uniswapV2Router.addLiquidity(
            address(this),
            address(WETH),
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

    function rescueERC20(address token, uint256 _amount) external onlyOwner {
        IERC20(token).transfer(owner(), _amount);
    }
}
