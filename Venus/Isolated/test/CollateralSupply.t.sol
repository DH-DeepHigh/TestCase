// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";
import {Action} from "../src/interfaces/IComptroller.sol";

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

    function test_supply_simple() public {
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

    function test_supply_simple2() public {
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

    function test_supply_checkPause() public {

        Pause(address(comptroller), address(vETH));
        assertEq(isPaused(address(comptroller), address(vETH), Action.MINT), true);
        unPause(address(comptroller), address(vETH));
        assertEq(isPaused(address(comptroller), address(vETH), Action.MINT), false);

        // Simulation
        Pause(address(comptroller), address(vETH));

        vm.startPrank(user);
        vm.expectRevert();
        vETH.mint(amount);
        vm.stopPrank();

        unPause(address(comptroller), address(vETH));

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

    function test_supply_checkMarket() public {

        vm.startPrank(admin);
        assertEq(comptroller.isMarketListed(address(NOT_REGISTERED_VTOKEN)), false);

        vm.expectRevert(); // 0xb5343d72. error MarketNotListed
        comptroller.unlistMarket(address(NOT_REGISTERED_VTOKEN));

        assertEq(comptroller.isMarketListed(address(vETH)), true);
        vm.stopPrank();
    }

    function test_supply_checkAccrueBlock() public {
        vm.startPrank(user);
        vETH.mint(amount);
        assertEq(vETH.accrualBlockNumber(), block.number);
    }
}
