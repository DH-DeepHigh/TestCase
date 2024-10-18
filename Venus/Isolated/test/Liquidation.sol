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
        USDT.approve(address(vUSDD), borrowAmount * 10);
        vm.stopPrank();
    }

    // function test_liquidate() public { Testing...
    //     vm.startPrank(user);
    //     vUSDT.mint(amount);

    //     address[] memory vTokens = new address[](1);
    //     vTokens[0] = address(vUSDT);
    //     gComptroller.enterMarkets(vTokens);        

    //     address[] memory assetsIn = gComptroller.getAssetsIn(user);
    //     assertEq(assetsIn[0], address(vUSDT));

        
    //     vUSDD.borrow(borrowAmount);

    //     assertEq(USDD.balanceOf(user), borrowAmount);
    //     vm.stopPrank();

    //     console.log("oracle price before : ", oracle.getUnderlyingPrice(address(vUSDT)));
    //     uint newPrice = oracle.getUnderlyingPrice(address(vUSDT)) / 10000;
    //     vm.mockCall(
    //         address(oracle),
    //         abi.encodeWithSelector(oracle.getUnderlyingPrice.selector, address(vUSDT)),
    //         abi.encode(newPrice) 
    //     );
    //     console.log("oracle price after : ", oracle.getUnderlyingPrice(address(vUSDT)));

    //     vm.startPrank(user2);

    //     vUSDT.liquidateBorrow(user, borrowAmount, vUSDD);

    //     uint seizedCollateral = vUSDT.balanceOf(user2);
    //     console.log("User2 seized collateral: ", seizedCollateral);

    //     vm.stopPrank();
    // }
    
}
