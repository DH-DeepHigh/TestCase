// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";

contract CollateralSupply is Test, Tester {

    address user = address(0x1234);
    address user2 = address(0x2345);
    uint amount = 10000 * 1e6;  // USDT는 6 decimals

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(ETH), user, amount);
        deal(address(ETH), user2, amount);

        vm.startPrank(user);
        ETH.approve(address(vETH), amount);
        vm.stopPrank();

        vm.startPrank(user2);
        ETH.approve(address(vETH), amount);
        vm.stopPrank();
    }

    function test_mint() public {
        vm.startPrank(user);
        vETH.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vETH);
        comptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = comptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vETH));

        (, uint collateralFactorMantissa) = comptroller.markets(address(vETH));
        (, uint liquidity,) = comptroller.getAccountLiquidity(user);
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vETH));
        uint expectedLiquidity = (price * amount * collateralFactorMantissa) / 1e18 / 1e18;
        assertEq(liquidity, expectedLiquidity);
        vm.stopPrank();
    }

    function test_mintBehalf() public {
        vm.startPrank(user);
        vETH.mintBehalf(user2, amount);
        vm.stopPrank();

        vm.startPrank(user2);
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vETH);
        comptroller.enterMarkets(vTokens);

        (, uint collateralFactorMantissa) = comptroller.markets(address(vETH));
        (, uint liquidity,) = comptroller.getAccountLiquidity(user2);
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vETH));
        uint expectedLiquidity = (price * amount * collateralFactorMantissa) / 1e18 / 1e18;
        assertEq(liquidity, expectedLiquidity);
        vm.stopPrank();
    }

    function test_borrow() public { //testing...
        vm.startPrank(user);
        vETH.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vETH);
        comptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = comptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vETH));

        uint borrowAmount = 100 * 1e18;
        vweETH.borrow(borrowAmount);

        assertEq(weETH.balanceOf(user), borrowAmount);
        vm.stopPrank();
        
    }
}
