// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";

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

    function test_repay() public { //testing...
        vm.startPrank(user);
        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vUSDT));

        uint borrowAmount = 10 * 1e18;
        vUSDD.borrow(borrowAmount);
        assertEq(USDD.balanceOf(user), borrowAmount);

        
        vUSDD.repayBorrow(borrowAmount);
        assertEq(USDD.balanceOf(user), 0);
        vm.stopPrank();
    }

    function test_repayBorrowBehalf() public {
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
}
