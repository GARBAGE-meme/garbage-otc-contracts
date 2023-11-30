// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract GarbageSaleTestSuit is TestHelper {
    function setUp() public virtual override {
        super.setUp();
        saleContractV1 = new GarbageSaleV1Harness(
            address(priceFeed),
            tokenPrice,
            saleLimit,
            owner
        );
        saleContractV2 = new GarbageSaleV2Harness(
            address(priceFeed),
            tokenPrice,
            saleLimit,
            owner,
            address(saleContractV1)
        );
    }

    function test_SetUpState(address _user) public {
        assertEq(address(saleContractV2.priceFeed()), address(priceFeed));
        assertEq(saleContractV2.tokenPrice(), tokenPrice);
        assertEq(saleContractV2.saleLimit(), saleLimit * 1e18);
        (uint256 ethSpent, uint256 tokensPurchased) = saleContractV2._users(_user);
        assertEq(ethSpent, 0);
        assertEq(tokensPurchased, 0);
    }

    function test_Purchase_OK_SinglePurchase(address _user, uint256 _randomUint) public {
        vm.assume(_user != 0x0000000000000000000000000000000000003039);
        uint256 ethAmount = bound(_randomUint, 0.1 ether, 5 ether);
        deal(_user, ethAmount + 1 ether);

        (, uint256 tokensAmount) = saleContractV2.convertETHToTokensAmount(ethAmount);

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount }("");

        (uint256 ethSpent, uint256 tokensPurchased) = saleContractV2._users(_user);
        assertEq(ethSpent, ethAmount);
        assertEq(tokensPurchased, tokensAmount);
        assertEq(owner.balance, ethAmount);
    }

    function test_Purchase_OK_SeveralPurchases(address _user, uint256 _randomUint) public {
        vm.assume(_user != 0x0000000000000000000000000000000000003039);
        uint256 ethAmount = bound(_randomUint, 0.1 ether, 2.5 ether);
        deal(_user, ethAmount * 2 + 1 ether);

        (, uint256 tokensAmount) = saleContractV2.convertETHToTokensAmount(ethAmount);

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount }("");

        (uint256 ethSpent, uint256 tokensPurchased) = saleContractV2._users(_user);
        assertEq(ethSpent, ethAmount);
        assertEq(tokensPurchased, tokensAmount);
        assertEq(owner.balance, ethAmount);

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount }("");

        (ethSpent, tokensPurchased) = saleContractV2._users(_user);
        assertEq(ethSpent, ethAmount * 2);
        assertEq(tokensPurchased, tokensAmount * 2);
        assertEq(owner.balance, ethAmount * 2);
    }

    function test_Purchase_OK_SeveralPurchases_MultiContract(address _user, uint256 _randomUint) public {
        emit log_address(address(this));
        uint256 ethAmount = bound(_randomUint, 0.1 ether, 2.5 ether);
        deal(_user, ethAmount * 2 + 1 ether);

        (, uint256 tokensAmount) = saleContractV2.convertETHToTokensAmount(ethAmount);

        vm.prank(_user);
        payable(address(saleContractV1)).call{ value: ethAmount }("");

        (uint256 ethSpent, uint256 tokensPurchased) = saleContractV2.users(_user);
        assertEq(ethSpent, ethAmount);
        assertEq(tokensPurchased, tokensAmount);
        assertEq(owner.balance, ethAmount);

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount }("");

        (ethSpent, tokensPurchased) = saleContractV2.users(_user);
        assertEq(ethSpent, ethAmount * 2);
        assertEq(tokensPurchased, tokensAmount * 2);
        assertEq(owner.balance, ethAmount * 2);
    }

    function test_Purchase_Revert_TooLowValue(address _user, uint256 _randomUint) public {
        vm.assume(_user != 0x0000000000000000000000000000000000003039);
        uint256 ethAmount = bound(_randomUint, 0 ether, 0.1 ether);
        deal(_user, ethAmount + 1 ether);

        (, uint256 tokensAmount) = saleContractV2.convertETHToTokensAmount(ethAmount);

        vm.expectRevert(abi.encodeWithSelector(TooLowValue.selector));

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount }("");
    }

    function test_Purchase_Revert_PerWalletLimitExceeded_SinglePurchase(address _user, uint256 _randomUint) public {
        vm.assume(_user != 0x0000000000000000000000000000000000003039);
        uint256 ethAmount = bound(_randomUint, 5 ether, 1e5 ether);
        deal(_user, ethAmount + 1 ether);

        (, uint256 tokensAmount) = saleContractV2.convertETHToTokensAmount(ethAmount);

        vm.expectRevert(abi.encodeWithSelector(PerWalletLimitExceeded.selector));

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount }("");
    }

    function test_Purchase_Revert_PerWalletLimitExceeded_SeveralPurchases(address _user, uint256 _randomUint) public {
        vm.assume(_user != 0x0000000000000000000000000000000000003039);
        uint256 ethAmount = bound(_randomUint, 5 ether + 1, 9 ether);
        deal(_user, ethAmount + 1 ether);

        (, uint256 tokensAmount) = saleContractV2.convertETHToTokensAmount(ethAmount / 2);

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount / 2 }("");

        (uint256 ethSpent, uint256 tokensPurchased) = saleContractV2._users(_user);
        assertEq(ethSpent, ethAmount / 2);
        assertEq(tokensPurchased, tokensAmount);
        assertEq(owner.balance, ethAmount / 2);

        vm.expectRevert(abi.encodeWithSelector(PerWalletLimitExceeded.selector));

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount / 2 }("");
    }

    function test_Purchase_Revert_PerWalletLimitExceeded_SeveralPurchases_TwoContracts(address _user, uint256 _randomUint) public {
        vm.assume(_user != 0x0000000000000000000000000000000000003039);
        uint256 ethAmount = bound(_randomUint, 5 ether + 1, 9 ether);
        deal(_user, ethAmount + 1 ether);

        (, uint256 tokensAmount) = saleContractV1.convertETHToTokensAmount(ethAmount / 2);

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount / 2 }("");

        (uint256 ethSpent, uint256 tokensPurchased) = saleContractV2._users(_user);
        assertEq(ethSpent, ethAmount / 2);
        assertEq(tokensPurchased, tokensAmount);
        assertEq(owner.balance, ethAmount / 2);

        vm.expectRevert(abi.encodeWithSelector(PerWalletLimitExceeded.selector));

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount / 2 }("");
    }

    function test_Purchase_Revert_SaleLimitExceeded(address _user, uint256 _randomUint) public {
        vm.assume(_user != 0x0000000000000000000000000000000000003039);
        uint256 ethAmount = bound(_randomUint, 0.1 ether, 5 ether);
        deal(_user, ethAmount + 1 ether);

        (, uint256 tokensAmount) = saleContractV2.convertETHToTokensAmount(ethAmount);

        saleContractV2.setSaleLimitHarness(tokensAmount - 1);

        vm.expectRevert(abi.encodeWithSelector(SaleLimitExceeded.selector));

        vm.prank(_user);
        payable(address(saleContractV2)).call{ value: ethAmount }("");
    }

    function test_Purchase_convertETHToTokensAmount_OK(uint256 _ethAmount, uint256 _ethPrice) public {
        vm.assume(_ethPrice <= type(uint32).max);
        vm.assume(_ethAmount <= type(uint32).max);
        vm.assume(_ethAmount > 0);
        vm.assume(_ethPrice > 0);
        priceFeed.setPrice(int256(_ethPrice * 100));

        (uint256 ethPrice, uint256 tokensAmount) = saleContractV2.convertETHToTokensAmount(_ethAmount);

        assertEq(ethPrice, _ethPrice * 1e6);
        assertEq(tokensAmount, _ethAmount * _ethPrice * 1e6 / saleContractV2.tokenPrice());
    }
}
