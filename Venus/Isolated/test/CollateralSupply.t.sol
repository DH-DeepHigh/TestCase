// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";

contract CollateralSupply is Test, Tester {

    address user = address(0x1234);
    address user2 = address(0x2345);
    uint amount = 1000 * 1e18;

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
        (, uint collateralFactorMantissa) = comptroller.markets(address(vETH));
        (, uint liquidity,) = comptroller.getAccountLiquidity(user2);
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vETH));
        uint expectedLiquidity = (price * amount * collateralFactorMantissa) / 1e18 / 1e18;
        assertEq(liquidity, expectedLiquidity);
        vm.stopPrank();
    }
}
