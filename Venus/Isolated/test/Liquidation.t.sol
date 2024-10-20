// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";

contract CollateralSupply is Test, Tester {

    address user = address(0x1234);
    address user2 = address(0x2345);
    uint amount = 1000 * 1e18;
    uint borrowAmount = 100 * 1e18;

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(USDT), user, amount);
        deal(address(USDD), user2, borrowAmount * 10);

        vm.startPrank(user);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();

        vm.startPrank(user2);
        USDD.approve(address(vUSDD), borrowAmount * 10);
        vm.stopPrank();

        // user's Borrowing
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

    function test_liquidate_checkMarket() public {

        vm.startPrank(user2);
        uint factor = gComptroller.closeFactorMantissa();
        uint borrowed = vUSDD.borrowBalanceCurrent(user);
        uint liquidateAmount = (borrowed * factor) / 1e18;

        vm.expectRevert();
        vUSDD.liquidateBorrow(user, liquidateAmount, NOT_REGISTERED_VTOKEN);
        // set_oracle();
        // vUSDD.liquidateBorrow(user, liquidateAmount, vUSDT);
        vm.stopPrank();
    }

    function test_liquidate_checkLTV() public {
        vm.startPrank(user2);
        uint factor = gComptroller.closeFactorMantissa();
        uint borrowed = vUSDD.borrowBalanceCurrent(user);
        uint liquidateAmount = (borrowed * factor) / 1e18;

        vm.expectRevert();  // 0x095bf333. error InsufficientShortfall
        vUSDD.liquidateBorrow(user, liquidateAmount, vUSDT);
        vm.stopPrank();

    }

    // function set_oracle() public {
    //     uint newPrice = oracle.getUnderlyingPrice(address(vUSDT)) / 9;
    //     vm.mockCall(
    //         address(oracle),
    //         abi.encodeWithSelector(oracle.getUnderlyingPrice.selector, address(vUSDT)),
    //         abi.encode(newPrice) 
    //     );
    // }
    
}
