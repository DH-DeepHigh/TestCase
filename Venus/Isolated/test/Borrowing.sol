// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";
import {Action} from "../src/interfaces/IComptroller.sol";

contract CollateralSupply is Test, Tester {

    address user = address(0x1234);
    address user2 = address(0x2345);
    address rich_man = address(0x9876);
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


    function test_borrow_simple() public {
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

    function test_borrow_simple2() public {
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
        vUSDD.borrowBehalf(user, borrowAmount);

        assertEq(USDD.balanceOf(user2), borrowAmount);
        assertEq(vUSDD.borrowBalanceCurrent(user), borrowAmount);
        vm.stopPrank();
        
    }

    function test_borrow_checkPause() public {
        Pause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.BORROW), true);
        unPause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.BORROW), false);
    }

    function test_borrow_checkMarket() public {
        vm.startPrank(admin);
        assertEq(gComptroller.isMarketListed(address(NOT_REGISTERED_VTOKEN)), false);

        vm.expectRevert(); // 0xb5343d72. error MarketNotListed
        gComptroller.unlistMarket(address(NOT_REGISTERED_VTOKEN));

        assertEq(gComptroller.isMarketListed(address(vUSDT)), true);
        vm.stopPrank();
    }

    function test_borrow_checkAccrueBlock() public {
        vm.startPrank(user);
        vUSDT.mint(amount);
        vUSDT.borrow(vUSDT.balanceOf(user) / 2);
        assertEq(vUSDT.accrualBlockNumber(), block.number);
    }

    function test_borrow_checkOut() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

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

    function test_borrow_checkAmount() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(123456789);
        assertEq(USDD.balanceOf(user), 123456789);
        vm.stopPrank();
    }

    function test_borrow_checkMembership() public {
        vm.startPrank(user);
        bool result = gComptroller.checkMembership(user, address(vUSDT));
        assertEq(result, false);

        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(borrowAmount);
        result = gComptroller.checkMembership(user, address(vUSDT));
        assertEq(result, true);
    }

    function test_borrow_checkBorrowCap() public {
        uint totalBorrow = vUSDD.totalBorrowsCurrent();
        uint borrowCap = gComptroller.borrowCaps(address(vUSDD));
        uint gap = borrowCap - totalBorrow;
        console.log("totalBorrow : ", totalBorrow);
        console.log("borrowCap : ", borrowCap);

        require(borrowCap >= totalBorrow, "borrowCap is less than totalBorrow");

        vm.startPrank(rich_man);

        deal(address(vUSDT), rich_man, 10000000 * 1e18);
        
        vm.expectRevert();
        vUSDD.borrow(gap + 1);
        vUSDT.borrow(vUSDT.balanceOf(user));
    }

    function test_borrow_checkLTV() public {
        vm.startPrank(user);
        vUSDT.mint(amount);

        address[] memory vToken = new address[](1);
        vToken[0] = address(vUSDT);
        gComptroller.enterMarkets(vToken);

        (,,uint shortfall) = gComptroller.getHypotheticalAccountLiquidity(user, address(vUSDT), 0, amount);
        console.log("shortfall : ", shortfall);
        assertGt(shortfall, 0);

        vm.expectRevert();
        vUSDT.borrow(amount);
        vUSDT.borrow(borrowAmount);

    }
    
}
