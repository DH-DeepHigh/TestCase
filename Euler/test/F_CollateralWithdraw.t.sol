// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EVaultTestBase} from "./forkUtils/testBase/EVaultTestBase.sol";
import {Events} from "../src/EVault/shared/Events.sol";
import {SafeERC20Lib} from "../src/EVault/shared/lib/SafeERC20Lib.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {IEVault} from "../src/EVault/IEVault.sol";
import {TestERC20} from "./forkUtils/mocks/TestERC20.sol";
import {IRMTestZero} from "./forkUtils/mocks/IRMTestZero.sol";
import {Errors} from "../src/EVault/shared/Errors.sol";

import "../src/EVault/shared/types/Types.sol";
import "../src/EVault/shared/Constants.sol";

import "forge-std/Test.sol";

contract Test_CollateralWithdraw is EVaultTestBase {   
    using stdStorage for StdStorage;
    using TypesLib for uint256;

    address user;
    address lender;

    function setUp() public override {
        super.setUp();
        cheat.createSelectFork("eth_mainnet", BLOCK_NUMBER);

        user = makeAddr("user");
        lender = makeAddr("lender");

        // user 
        vm.startPrank(user);

        deal(address(WETH), user, type(uint256).max);
        WETH.approve(address(eWETH), type(uint256).max);
        eWETH.deposit(10 * 1e18, user);

        vm.stopPrank();
    }

    function test_withdraw_simple() public {
        uint256 withdrawAmount = 25_000 * 1e18; // withdraw될 asset
        uint256 expectedBurnedShares = eWETH.previewWithdraw(withdrawAmount);

        uint256 assetBalanceBefore = WETH.balanceOf(user);
        uint256 shareBalanceBefore = eWETH.balanceOf(user);

        vm.startPrank(user);
        eWETH.withdraw(withdrawAmount, user, user);

        uint256 assetBalanceAfter = WETH.balanceOf(user);
        uint256 shareBalanceAfter = eWETH.balanceOf(user);

        assertEq(withdrawAmount, assetBalanceAfter - assetBalanceBefore);
        assertEq(expectedBurnedShares, shareBalanceBefore - shareBalanceAfter);
    }

    function test_withdraw_liquidity_check() public {  
        uint256 borrowAmount = 10_000 * 1e18;
        vm.startPrank(lender);
        
        deal(address(DAI), lender, type(uint256).max);
        DAI.approve(address(eDAI), type(uint256).max);
        eDAI.deposit(1_000_000 * 1e18, lender);

        vm.startPrank(user);
        
        evc.enableController(user, address(eDAI));
        evc.enableCollateral(user, address(eWETH));

        eDAI.borrow(borrowAmount, user);
        assertEq(DAI.balanceOf(user), borrowAmount);

        (uint256 collateralValue, uint256 liabilityValue) = eDAI.accountLiquidity(user, false);
        collateralValue = collateralValue * 1e4 / eDAI.LTVBorrow(address(eWETH));
        uint256 withdrawableValue = collateralValue - liabilityValue;
        (withdrawableValue, ) = oracle.getQuotes(withdrawableValue, unitOfAccount, eWETH.asset());

        vm.expectRevert(); // unhealthy revert
        eWETH.withdraw(withdrawableValue + 1, user, user);

        eWETH.withdraw(withdrawableValue, user, user);
    }

    function test_withdraw_below_total_balance() public {        
        uint256 assetBalanceBefore = WETH.balanceOf(user);
        uint256 shareBalanceBefore = eWETH.balanceOf(user);

        uint256 eWETHBalance = WETH.balanceOf(address(eWETH));
        uint256 expectedBurnedShares = eWETH.previewWithdraw(eWETHBalance);
        vm.startPrank(user);

        vm.expectRevert(Errors.E_InsufficientCash.selector);
        eWETH.withdraw(eWETHBalance + 1, user, user);

        vm.expectRevert(Errors.E_InsufficientBalance.selector);
        eWETH.withdraw(eWETHBalance, user, user);
    }

    function test_maximum_withdraw() public {
        // uint256 maxWithdrawAmount = eWETH.maxWithdraw(borrower); // withdraw될 asset의 총량
        // uint256 expectedBurnedShares = eWETH.previewWithdraw(maxWithdrawAmount); // withdraw될 easset의 총량
        
        // uint256 assetBalanceBefore = WETH.balanceOf(borrower); // deposit상태에서 asset의 잔액 
        // uint256 shareBalanceBefore = eWETH.balanceOf(borrower); //  '' eTST의 잔액
        
        // startHoax(borrower);
        // console.log(WETH.balanceOf(address(eWETH)));
        // console.log(maxWithdrawAmount);

        // vm.expectRevert(Errors.E_InsufficientBalance.selector);
        // eWETH.withdraw(maxWithdrawAmount + WETH_cash_before, borrower, borrower); // 가지고 있는 balance보다 더 많이 가져가려고 하면 안됨

        // vm.expectRevert(Errors.E_InsufficientCash.selector);
        // eWETH.withdraw(maxWithdrawAmount + WETH_cash_before + 1, borrower, borrower); // vault가 가지고있는 전체 돈보다 많이 가져가려고 하면 안됨

        // eWETH.withdraw(maxWithdrawAmount, borrower, borrower);

        // uint256 assetBalanceAfter = WETH.balanceOf(borrower);
        // uint256 shareBalanceAfter = eWETH.balanceOf(borrower);

        // assertEq(maxWithdrawAmount, assetBalanceAfter - assetBalanceBefore);
        // assertEq(shareBalanceBefore - shareBalanceAfter, expectedBurnedShares);
    }

    function test_evc_maximum_withdraw() public {}

    function test_basic_redeem() public {}

    function test_maximum_redeem() public {}

    function test_evc_maximum_redeem() public {}
}
