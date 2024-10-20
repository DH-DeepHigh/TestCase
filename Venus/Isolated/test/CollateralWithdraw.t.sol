// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";
import {Action} from "../src/interfaces/IComptroller.sol";

contract CollateralSupply is Test, Tester {

    address user = address(0x1234);
    address user2 = address(0x2345);
    uint amount = 10000 * 1e18;
    uint piece = 1e18;

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(USDT), user, amount);
        deal(address(USDT), user2, piece);
        deal(address(USDT), admin, amount);

        vm.startPrank(user);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();

        vm.startPrank(user2);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();

        vm.startPrank(admin);
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

    function test_withdraw_simple() public {
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

    function test_withdraw_simple2() public {
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

    function test_withdraw_simpleUnderlying() public {

        vm.startPrank(user2);
        console.log("before redeem USDT : ", USDT.balanceOf(user2));
        vUSDT.mint(piece);
        
        console.log("before redeem vUSDT : ", vUSDT.balanceOf(user2));
        
        uint redeemAmount = piece * 9999999 / 10000000;
        console.log("Redeem Amount (in USDT): ", redeemAmount);

        vUSDT.redeemUnderlying(redeemAmount);

        // https://github.com/VenusProtocol/isolated-pools/blob/develop/contracts/VToken.sol
        // Line 977 ~ 979 div_ 및 mul_ 연산과정 후 Line 980에서 round up. 소수점 보정을 위해 redeemToken++. 
        // Core Poll과 다른 이 과정에서 오차 발생 예상
        assertGt(USDT.balanceOf(user2), redeemAmount);
        
        uint remainingVUSDT = vUSDT.balanceOf(user2);
        assert(remainingVUSDT > 0);
        vm.stopPrank();

        vm.startPrank(user);
        vUSDT.mint(amount);

        redeemAmount = amount / 2;
        vUSDT.redeemUnderlying(redeemAmount);

        // 오차 발생
        uint tolerance = 1e10 wei;
        assertApproxEqAbs(USDT.balanceOf(user), redeemAmount, tolerance);
        assertLt(USDT.balanceOf(user), redeemAmount + 1e10);
        assertGt(USDT.balanceOf(user), redeemAmount + 1e9);

        vm.stopPrank();

    }

    function test_withdraw_checkPause() public {
        Pause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.REDEEM), true);
        unPause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.REDEEM), false);
    }

    function test_withdraw_checkMarket() public {
        vm.startPrank(admin);
        assertEq(gComptroller.isMarketListed(address(NOT_REGISTERED_VTOKEN)), false);

        vm.expectRevert(); // 0xb5343d72. error MarketNotListed
        gComptroller.unlistMarket(address(NOT_REGISTERED_VTOKEN));

        assertEq(gComptroller.isMarketListed(address(vUSDT)), true);
        vm.stopPrank();
    }

    function test_withdraw_checkAccrueBlock() public {
        vm.startPrank(user);
        vUSDT.mint(amount);
        vUSDT.redeem(vUSDT.balanceOf(user));
        assertEq(vUSDT.accrualBlockNumber(), block.number);
    }

    function test_withdraw_checkOut() public {
        vm.startPrank(user);
        vUSDT.mint(amount);
        assertEq(vUSDT.borrowBalanceCurrent(user), 0);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens); 

        address[] memory assetsIn = gComptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(1);

        vm.expectRevert();  // 0xbb55fd27. error InsufficientLiquidity
        gComptroller.exitMarket(address(vUSDT));
        vm.stopPrank();
    }

    function test_withdraw_checkAmount() public {   // Testing...
        vm.startPrank(user);
        vUSDT.mint(amount);

        uint test = getExchangeRate();
        uint exchangeRate = vUSDT.exchangeRateCurrent();
        assertEq(test, exchangeRate);

        uint vUSDTAmount = vUSDT.balanceOf(user);
        uint mintTokens = amount * 1e18 / exchangeRate;
        assertEq(vUSDTAmount, mintTokens);

        vm.expectRevert();
        vUSDT.redeem(mintTokens + 1);
    }

    function test_withdraw_checkLTV() public {  // Testing...
        vm.startPrank(user);
        vUSDT.mint(amount);

        address[] memory vToken = new address[](1);
        vToken[0] = address(vUSDT);
        gComptroller.enterMarkets(vToken);

        uint value = vUSDT.balanceOf(user);
        
        (,,uint shortfall) = gComptroller.getHypotheticalAccountLiquidity(user, address(vUSDT), value + 1, 0);
        console.log("shortfall : ", shortfall);
        assertGt(shortfall, 0);

        vm.expectRevert();
        vUSDT.redeem(value + 1);
    }
}
