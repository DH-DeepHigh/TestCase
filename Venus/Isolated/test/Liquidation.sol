// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";
// import {IComptroller} from "../src/interfaces/IComptroller.sol";

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
    }

    function test_liquidate() public {
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

        console.log("oracle price before : ", oracle.getUnderlyingPrice(address(vUSDT)));
        uint newPrice = oracle.getUnderlyingPrice(address(vUSDT)) / 9;
        vm.mockCall(
            address(oracle),
            abi.encodeWithSelector(oracle.getUnderlyingPrice.selector, address(vUSDT)),
            abi.encode(newPrice) 
        );
        console.log("oracle price after : ", oracle.getUnderlyingPrice(address(vUSDT)));

        vm.startPrank(user2);
        uint factor = gComptroller.closeFactorMantissa();
        uint borrowed = vUSDD.borrowBalanceCurrent(user);
        uint liquidateAmount = (borrowed * factor) / 1e18;

        // 급락으로 인한 청산 가능가 이하의 경우 comptroller의 healAccount 혹은 liquidateAccount를 이용해야 함.
        // IComptroller.LiquidationOrder[] memory orders = new IComptroller.LiquidationOrder[](1);
        // orders[0] = IComptroller.LiquidationOrder({
        //     vTokenBorrowed: address(vUSDD),
        //     vTokenCollateral: address(vUSDT),
        //     repayAmount: liquidateAmount
        // });
        // gComptroller.liquidateAccount(user, orders);

        vm.expectRevert();
        vUSDD.liquidateBorrow(user, liquidateAmount + 1, vUSDT);
        vUSDD.liquidateBorrow(user, liquidateAmount, vUSDT);

        vm.stopPrank();
    }
    
}
