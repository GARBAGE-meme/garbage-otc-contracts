// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract GarbageTokenTestSuite is TestHelper {
    IUniswapV2Pair public pairContract = IUniswapV2Pair(0x35318373409608AFC0f2cdab5189B3cB28615008);

    function setUp() public override {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
        tokenContract = new GarbageToken(1e8 * 1e18, address(this));
    }

    function test_listing_Ok(address _owner) public {
        vm.assume(_owner != address(0));
        vm.assume(_owner != address(this));
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);

        tokenContract.transferOwnership(_owner);

        vm.prank(_owner);
        tokenContract.createPairAndAddLiquidity();

        (uint112 _reserve0, uint112 _reserve1, ) = pairContract.getReserves();

        assertEq(tokenContract.WETH().balanceOf(_owner), 0);
        assertEq(tokenContract.balanceOf(_owner), 0);
        assertEq(_reserve0, 1e6 * 1e18);
        assertEq(_reserve1, 10 * 1e18);
        assertGe(address(pairContract).code.length, 0);
    }

    function test_listing_Revert_WhenCalledByNonOwner(address _nonOwner) public {
        vm.assume(_nonOwner != address(0));
        vm.assume(_nonOwner != address(this));
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);

        vm.expectRevert();

        vm.prank(_nonOwner);
        tokenContract.createPairAndAddLiquidity();
    }

    function test_listing_Revert_WhenListingSecondTime() public {
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);
        tokenContract.createPairAndAddLiquidity();

        vm.expectRevert(abi.encodeWithSelector(AlreadyListed.selector));
        tokenContract.createPairAndAddLiquidity();
    }

    function test_transferIsBlockedAfterListing_Ok(address _user, uint256 _amount) public {
        vm.assume(_user != address(0));
        vm.assume(_user != address(tokenContract));
        vm.assume(_amount < 1e7 * 1e18);
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);
        tokenContract.transfer(_user, 1e6 * 1e18);
        tokenContract.createPairAndAddLiquidity();

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

    function test_swapAfterListing_Ok(address _user, uint256 _amount) public {
        vm.assume(_user != address(0));
        vm.assume(_amount < 1e5 * 1e18);
        vm.assume(_amount > 1000000);
        tokenContract.transfer(address(tokenContract), 1e6 * 1e18);
        deal(address(tokenContract.WETH()), address(tokenContract), 10 * 1e18);
        tokenContract.createPairAndAddLiquidity();
        vm.roll(block.number+6);

        tokenContract.transfer(_user, 1e6 * 1e18);

        address[] memory path = new address[](2);
        path[0] = address(tokenContract);
        path[1] = address(tokenContract.WETH());

        vm.prank(_user);
        tokenContract.approve(address(tokenContract.uniswapV2Router()), _amount);

        vm.prank(_user);
        tokenContract.approve(address(tokenContract.uniswapV2Router()), _amount);

        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pairContract.getReserves();

        emit log_string("before");
        emit log_uint(_reserve0);
        emit log_uint(_reserve1);

        uint[] memory amounts = getAmountsOut(address(tokenContract.uniswapV2Router().factory()), _amount, path);

        emit log_string("after");
        emit log_uint(amounts.length);
        for (uint256 i=0;i<amounts.length;i++){
            emit log_uint(amounts[i]);
        }

        emit log_uint(_amount * 990 / 1e8);

        vm.prank(_user);
        IUniswapV2RouterWithSwap(address(tokenContract.uniswapV2Router())).swapExactTokensForTokens(_amount, amounts[1], path, address(this), block.timestamp+1);
    }
}
