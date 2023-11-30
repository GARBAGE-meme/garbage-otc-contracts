// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract GarbageTokenTestSuite is TestHelper {
    IUniswapV2Pair public pairContract = IUniswapV2Pair(0x35318373409608AFC0f2cdab5189B3cB28615008);

    event HoldLimitEnabled();
    event HoldLimitDisabled();
    event HoldLimitValueSet(uint256 newValue);
    event PairCreated(address pairAddress);
    event LiquidityProvided(uint256 tokenAmount, uint256 wethAmount, uint256 block, uint256 timestamp);

    function setUp() public override {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
        tokenContract = new GarbageToken(1e8 * 1e18, address(this));
    }

    /// forge-config: default.fuzz.runs = 10
    function test_listing_Ok(address _owner) public {
        vm.assume(_owner != address(0));
        vm.assume(_owner != address(this));
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);

        tokenContract.transferOwnership(_owner);

        vm.expectEmit(false,false,false,false);
        emit PairCreated(0x35318373409608AFC0f2cdab5189B3cB28615008);

        vm.prank(_owner);
        tokenContract.createPair();

        vm.expectEmit(true,true,true,true);
        emit LiquidityProvided(1e6 * 1e18, 10 * 1e18, block.number, block.timestamp);

        vm.expectEmit(true,true,true,true);
        emit HoldLimitEnabled();

        vm.expectEmit(true,true,true,true);
        emit HoldLimitValueSet(1e6 * 1e18 / 100);

        vm.prank(_owner);
        tokenContract.provideLiquidity(true);

        (uint112 _reserve0, uint112 _reserve1, ) = pairContract.getReserves();

        assertEq(tokenContract.WETH().balanceOf(_owner), 0);
        assertEq(tokenContract.balanceOf(_owner), 0);
        assertEq(_reserve0, 1e6 * 1e18);
        assertEq(_reserve1, 10 * 1e18);
        assertGe(address(pairContract).code.length, 0);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_createPair_Ok(address _nonOwner) public {
        vm.assume(_nonOwner != address(0));
        vm.assume(_nonOwner != address(this));
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);

        assertEq(address(tokenContract.uniswapPair()), address(0));

        vm.expectEmit(true,false,false,false);
        emit PairCreated(address(0));

        tokenContract.createPair();

        assertNotEq(address(tokenContract.uniswapPair()), address(0));
    }

    /// forge-config: default.fuzz.runs = 10
    function test_listing_Revert_WhenCalledByNonOwner(address _nonOwner) public {
        vm.assume(_nonOwner != address(0));
        vm.assume(_nonOwner != address(this));
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);

        vm.expectRevert();

        vm.prank(_nonOwner);
        tokenContract.createPair();
    }

    /// forge-config: default.fuzz.runs = 10
    function test_listing_Revert_WhenProvidingLiquidityBeforeCreatingPair(address _nonOwner) public {
        vm.assume(_nonOwner != address(0));
        vm.assume(_nonOwner != address(this));
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);

        vm.expectRevert(abi.encodeWithSelector(PairNotCreated.selector));

        tokenContract.provideLiquidity(true);
    }

    function test_listing_Revert_WhenListingSecondTime() public {
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);
        tokenContract.createPair();

        vm.expectRevert(abi.encodeWithSelector(PairAlreadyCreated.selector));
        tokenContract.createPair();
    }

    /// forge-config: default.fuzz.runs = 10
    function test_transferIsBlockedAfterListing_Ok(address _user, uint256 _amount) public {
        vm.assume(_user != address(0));
        vm.assume(_user != address(tokenContract));
        vm.assume(_amount < 1e7 * 1e18);
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);
        tokenContract.transfer(_user, 1e6 * 1e18);
        tokenContract.createPair();
        tokenContract.provideLiquidity(true);

        uint256 blockNumber = block.number;

        for (uint8 i = 0; i<6; i++){
            vm.roll(blockNumber++);
            vm.expectRevert(abi.encodeWithSelector(TransfersBlocked.selector));
            vm.prank(_user);
            tokenContract.transfer(address(tokenContract), _amount);
        }

        vm.roll(blockNumber++);
        vm.prank(_user);
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);

        assertEq(tokenContract.balanceOf(address(tokenContract)), 1e6 * 1e18);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_swapAfterListing_Ok_WhenPurchasingLessThanLimit(address _user, uint256 _amount) public {
        vm.assume(_user != address(0));
        vm.assume(_amount < 1e4 * 1e18);
        vm.assume(_amount > 1000000);
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);
        tokenContract.createPair();
        tokenContract.provideLiquidity(true);
        vm.roll(block.number+6);

        tokenContract.transfer(_user, _amount);

        address[] memory path = new address[](2);
        path[0] = address(tokenContract);
        path[1] = address(tokenContract.WETH());

        vm.prank(_user);
        tokenContract.approve(address(tokenContract.uniswapV2Router()), _amount);

        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pairContract.getReserves();

        uint[] memory amounts = getAmountsOut(address(tokenContract.uniswapV2Router().factory()), _amount, path);

        vm.prank(_user);
        IUniswapV2RouterWithSwap(address(tokenContract.uniswapV2Router())).swapExactTokensForTokens(_amount, amounts[1], path, address(this), block.timestamp+1);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_swapAfterListing_Ok_WhenHoldLimitTurnedOff(address _user, uint256 _amount) public {
        vm.assume(_user != address(0));
        vm.assume(_amount < 1e6 * 1e18);
        vm.assume(_amount > 1e4 * 1e18);
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);
        tokenContract.transfer(_user, _amount);
        tokenContract.createPair();
        tokenContract.provideLiquidity(true);
        vm.roll(block.number+6);

        address[] memory path = new address[](2);
        path[0] = address(tokenContract);
        path[1] = address(tokenContract.WETH());

        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pairContract.getReserves();

        uint[] memory amounts = getAmountsOut(address(tokenContract.uniswapV2Router().factory()), _amount, path);

        address router = address(tokenContract.uniswapV2Router());

        vm.prank(_user);
        tokenContract.approve(router, _amount);

        tokenContract.turnHoldLimitOff();

        vm.prank(_user);
        IUniswapV2RouterWithSwap(router).swapExactTokensForTokens(_amount, amounts[1], path, address(this), block.timestamp+1);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_swapAfterListing_Revert_WhenTryToPurchaseMoreThanLimit(address _user, uint256 _amount) public {
        vm.assume(_user != address(0));
        vm.assume(_amount < 1e6 * 1e18);
        vm.assume(_amount > 1e4 * 1e18);
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);
        tokenContract.transfer(_user, _amount);
        tokenContract.createPair();
        tokenContract.provideLiquidity(true);
        vm.roll(block.number+6);

        address[] memory path = new address[](2);
        path[0] = address(tokenContract);
        path[1] = address(tokenContract.WETH());

        vm.prank(_user);
        tokenContract.approve(address(tokenContract.uniswapV2Router()), _amount);

        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pairContract.getReserves();

        uint[] memory amounts = getAmountsOut(address(tokenContract.uniswapV2Router().factory()), _amount, path);

        address router = address(tokenContract.uniswapV2Router());

        vm.expectRevert();

        vm.prank(_user);
        IUniswapV2RouterWithSwap(router).swapExactTokensForTokens(_amount, amounts[1], path, address(this), block.timestamp+1);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_resqueERC20_Ok(uint256 _amount) public {
        vm.assume(_amount < 1e4 * 1e18);
        tokenContract.transfer(address(tokenContract), _amount);
        deal(address(tokenContract.WETH()), address(tokenContract), _amount);

        uint256 tokenAmountBefore = tokenContract.balanceOf(address(this));
        uint256 wethAmountBefore = tokenContract.WETH().balanceOf(address(this));

        tokenContract.rescueERC20(address(tokenContract.WETH()), _amount);
        tokenContract.rescueERC20(address(tokenContract), _amount);

        uint256 tokenAmountAfter = tokenContract.balanceOf(address(this));
        uint256 wethAmountAfter = tokenContract.WETH().balanceOf(address(this));

        assertEq(tokenAmountAfter, tokenAmountBefore + _amount);
        assertEq(wethAmountAfter, wethAmountBefore + _amount);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_resqueERC20_Revert_WhenCalledByNonOwner(uint256 _amount, address _nonOwner) public {
        vm.assume(_amount < 1e4 * 1e18);
        vm.assume(_nonOwner != address(this));
        tokenContract.transfer(address(tokenContract), _amount);
        deal(address(tokenContract.WETH()), address(tokenContract), _amount);

        address WETH = address(tokenContract.WETH());

        vm.expectRevert();
        vm.prank(_nonOwner);
        tokenContract.rescueERC20(WETH, _amount);

        vm.expectRevert();
        vm.prank(_nonOwner);
        tokenContract.rescueERC20(address(tokenContract), _amount);
    }

    function test_turnHoldingLimitOn_Ok() public {
        tokenContract.turnHoldLimitOn();

        assertTrue(tokenContract.isHoldLimitActive());
    }

    function test_turnHoldingLimitOn_Revert_WhenCalledByNonOwner(address _nonOwner) public {
        vm.assume(_nonOwner != address(this));

        vm.expectRevert();
        vm.prank(_nonOwner);
        tokenContract.turnHoldLimitOn();
    }

    function test_turnHoldingLimitOff_Ok(address _nonOwner) public {
        tokenContract.turnHoldLimitOn();
        assertTrue(tokenContract.isHoldLimitActive());

        tokenContract.turnHoldLimitOff();
        assertFalse(tokenContract.isHoldLimitActive());
    }

    function test_turnHoldingLimitOff_Revert_WhenCalledByNonOwner(address _nonOwner) public {
        vm.assume(_nonOwner != address(this));

        tokenContract.turnHoldLimitOn();
        assertTrue(tokenContract.isHoldLimitActive());

        vm.expectRevert();

        vm.prank(_nonOwner);
        tokenContract.turnHoldLimitOff();
    }
}
