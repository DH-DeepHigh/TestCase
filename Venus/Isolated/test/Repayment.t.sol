// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";
import {Action} from "../src/interfaces/IComptroller.sol";

contract CollateralSupply is Test, Tester {

    address user = address(0x1234);
    address user2 = address(0x2345);
    uint amount = 10000 * 1e18;
    uint borrowAmount = 10 * 1e18;

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(USDT), user, amount);
        deal(address(USDD), user2, borrowAmount);

        vm.startPrank(user);
        USDT.approve(address(vUSDT), amount);
        USDD.approve(address(vUSDD), borrowAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        USDT.approve(address(vUSDT), amount);
        USDT.approve(address(vUSDD), borrowAmount);
        vm.stopPrank();
    }

    function test_repay_simple() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(borrowAmount);
        assertEq(USDD.balanceOf(user), borrowAmount);

        
        vUSDD.repayBorrow(borrowAmount);
        assertEq(USDD.balanceOf(user), 0);
        vm.stopPrank();
    }

    function test_repay_simple2() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(borrowAmount);
        assertEq(USDD.balanceOf(user), borrowAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        USDD.approve(address(vUSDD), amount);
        vUSDD.repayBorrowBehalf(user, borrowAmount);
        assertEq(USDD.balanceOf(user2), 0);
        
        vm.stopPrank();
        
    }

    function test_repay_checkPause() public {
        Pause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.REPAY), true);
        unPause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.REPAY), false);
    }

    function test_repay_checkMarket() public {
        vm.startPrank(admin);
        assertEq(gComptroller.isMarketListed(address(NOT_REGISTERED_VTOKEN)), false);

        vm.expectRevert(); // 0xb5343d72. error MarketNotListed
        gComptroller.unlistMarket(address(NOT_REGISTERED_VTOKEN));

        assertEq(gComptroller.isMarketListed(address(vUSDT)), true);
        vm.stopPrank();
    }

    function test_repay_checkAccrueBlock() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(borrowAmount);
        assertEq(USDD.balanceOf(user), borrowAmount);

        
        vUSDD.repayBorrow(borrowAmount);
        assertEq(USDD.balanceOf(user), 0);
        assertEq(vUSDT.accrualBlockNumber(), block.number);
    }

    function test_repay_checkOut() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(1);
        vm.expectRevert();  // 0xbb55fd27. error InsufficientLiquidity
        gComptroller.exitMarket(address(vUSDT));

        vUSDD.repayBorrow(1);
        gComptroller.exitMarket(address(vUSDT));
        vm.stopPrank();
    }
    function test_repay_checkOut2() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(1);
        vm.expectRevert();  // 0xbb55fd27. error InsufficientLiquidity
        gComptroller.exitMarket(address(vUSDT));
        vm.stopPrank();

        vm.startPrank(user2);
        USDD.approve(address(vUSDD), amount);
        vUSDD.repayBorrowBehalf(user, borrowAmount);
        vm.stopPrank();

        vm.startPrank(user);
        gComptroller.exitMarket(address(vUSDT));
        vm.stopPrank();


    }
    function test_repay_checkAmount() public {}
}
