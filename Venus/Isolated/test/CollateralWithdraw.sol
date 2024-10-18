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
        deal(address(USDT), user, amount);
        deal(address(USDT), user2, amount);

        vm.startPrank(user);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();

        vm.startPrank(user2);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();
    }

    function getExchangeRate() internal returns (uint) {
        // exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply.
        uint totalCash = vUSDT.getCash();
        assertEq(totalCash, USDT.balanceOf(address(vUSDT)));

        uint totalBorrows = vUSDT.totalBorrowsCurrent();
        uint totalReserves = vUSDT.totalReserves();
        uint totalSupply = vUSDT.totalSupply();
        uint exchangeRate = 1e18 * (totalCash + totalBorrows  - totalReserves) / totalSupply;
        return exchangeRate;
    }

    function test_redeem() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

        uint test = getExchangeRate();
        uint exchangeRate = vUSDT.exchangeRateCurrent();
        assertEq(test, exchangeRate);

        uint vUSDTAmount = vUSDT.balanceOf(user);
        uint mintTokens = amount * 1e18 / exchangeRate;
        assertEq(vUSDTAmount, mintTokens);

        vm.roll(block.number + 100);
        vUSDT.redeem(vUSDT.balanceOf(user));
        assertEq(vUSDT.balanceOf(user), 0);

        //should have more bnb with 100 block of interests.
        assert(USDT.balanceOf(user) > amount);

        vm.stopPrank();
    }

    // Testing...
    // function test_redeemUnderlying() public {
    //     vm.startPrank(user);

    //     console.log("before USDT : ", USDT.balanceOf(user));

    //     vUSDT.mint(1e18);
    //     uint before = vUSDT.balanceOf(user);

    //     console.log("after mint : ", USDT.balanceOf(user));

    //     vUSDT.redeemUnderlying(1e18 / 2);
    //     // assertEq(, 1e18);

    // }
}
