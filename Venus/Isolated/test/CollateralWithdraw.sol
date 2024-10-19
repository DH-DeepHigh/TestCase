// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";

contract CollateralSupply is Test, Tester {

    address user = address(0x1234);
    address user2 = address(0x2345);
    uint amount = 10000 * 1e18;
    uint piece = 1e18;

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(USDT), user, amount);
        deal(address(USDT), user2, piece);

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

        vm.roll(block.number + 1);
        vUSDT.redeem(vUSDT.balanceOf(user));
        assertEq(vUSDT.balanceOf(user), 0);

        //should have more bnb with 100 block of interests.
        assert(USDT.balanceOf(user) > amount);
        vm.stopPrank();
    }

    function test_redeemBehalf() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

        gComptroller.updateDelegate(user2, true);
        vm.stopPrank();

        vm.roll(block.number + 1);

        vm.startPrank(user2);
        vUSDT.redeemBehalf(user, vUSDT.balanceOf(user));
        assertEq(vUSDT.balanceOf(user), 0);
        assert(USDT.balanceOf(user2) > amount);
        vm.stopPrank();
    }

    function test_redeemUnderlying() public {

        vm.startPrank(user2);
        vUSDT.mint(piece);
        console.log("before redeem USDT : ", USDT.balanceOf(user2));
        console.log("before redeem vUSDT : ", vUSDT.balanceOf(user2));
        
        uint redeemAmount = piece / 2;
        console.log("Redeem Amount (in USDT): ", redeemAmount);

        vUSDT.redeemUnderlying(redeemAmount);
        console.log("after redeemUnderlying USDT : ", USDT.balanceOf(user2));
        console.log("after redeemUnderlying vUSDT : ", vUSDT.balanceOf(user2));

        uint expectedUSDTBalance = redeemAmount;

        // https://github.com/VenusProtocol/isolated-pools/blob/develop/contracts/VToken.sol
        // Line 977 ~ 979 div_ 및 mul_ 연산과정 후 Line 980에서 round up 이 과정에서 1e10 범위의 오차 발생 예상
        uint tolerance = 1e10 wei;
        assertApproxEqAbs(USDT.balanceOf(user2), expectedUSDTBalance, tolerance);
        
        uint remainingVUSDT = vUSDT.balanceOf(user2);
        assert(remainingVUSDT > 0);
        vm.stopPrank();

    }
}
