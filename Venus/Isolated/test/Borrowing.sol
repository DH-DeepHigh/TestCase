// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";

contract CollateralSupply is Test, Tester {

    address user = address(0x1234);
    address user2 = address(0x2345);
    uint amount = 10000 * 1e18;
    uint borrowAmount = 100 * 1e18;

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(USDT), user, amount);
        deal(address(USDT), user2, amount);

        vm.startPrank(user);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();

        vm.startPrank(user2);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();
    }

    function test_borrow() public {
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
    }

    function test_borrowBehalf() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vUSDT));

        gComptroller.updateDelegate(user2, true);
        vm.stopPrank();

        vm.startPrank(user2);
        uint borrowAmount = 10 * 1e18;
        vUSDD.borrowBehalf(user, borrowAmount);

        assertEq(USDD.balanceOf(user2), borrowAmount);
        assertEq(vUSDD.borrowBalanceCurrent(user), borrowAmount);
        
    }
}
