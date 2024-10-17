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

    address lender;
    address borrower;

    uint WETH_cash_before;
    uint DAI_cash_before;

    function setUp() public override {
        super.setUp();
        cheat.createSelectFork("eth_mainnet", BLOCK_NUMBER);

        lender = makeAddr("lender");
        borrower = makeAddr("borrower");

        vm.label(address(WETH), "WETH");
        vm.label(address(eWETH), "eWETH");
        vm.label(address(DAI), "DAI");
        vm.label(address(eDAI), "eDAI");

        WETH_cash_before = eWETH.cash();
        DAI_cash_before = eDAI.cash();
        // lender 
        startHoax(borrower);
        deal(address(WETH), borrower, type(uint256).max);
        WETH.approve(address(eWETH), type(uint256).max);
        eWETH.deposit(100e18, borrower);

        // borrower  
        startHoax(lender);
        deal(address(DAI), lender, type(uint256).max);
        DAI.approve(address(eDAI), type(uint256).max);
        eDAI.deposit(100e18, lender);

        vm.stopPrank();
    }

    function test_basic_withdraw() public {
        uint256 withdrawAmount = 1e18; // withdraw될 asset
        uint256 expectedBurnedShares = eWETH.previewWithdraw(withdrawAmount);

        uint256 assetBalanceBefore = WETH.balanceOf(borrower);
        uint256 shareBalanceBefore = eWETH.balanceOf(borrower);

        startHoax(borrower);
        eWETH.withdraw(withdrawAmount, borrower, borrower);

        uint256 assetBalanceAfter = WETH.balanceOf(borrower);
        uint256 shareBalanceAfter = eWETH.balanceOf(borrower);

        assertEq(withdrawAmount, assetBalanceAfter - assetBalanceBefore);
        assertEq(expectedBurnedShares, shareBalanceBefore - shareBalanceAfter);
    }

    function test_maximum_withdraw() public {
        uint256 maxWithdrawAmount = eWETH.maxWithdraw(borrower); // withdraw될 asset의 총량
        uint256 expectedBurnedShares = eWETH.previewWithdraw(maxWithdrawAmount); // withdraw될 easset의 총량
        
        uint256 assetBalanceBefore = WETH.balanceOf(borrower); // deposit상태에서 asset의 잔액 
        uint256 shareBalanceBefore = eWETH.balanceOf(borrower); //  '' eTST의 잔액
        
        startHoax(borrower);
        console.log(WETH.balanceOf(address(eWETH)));
        console.log(maxWithdrawAmount);

        vm.expectRevert(Errors.E_InsufficientBalance.selector);
        eWETH.withdraw(maxWithdrawAmount + WETH_cash_before, borrower, borrower); // 가지고 있는 balance보다 더 많이 가져가려고 하면 안됨

        vm.expectRevert(Errors.E_InsufficientCash.selector);
        eWETH.withdraw(maxWithdrawAmount + WETH_cash_before + 1, borrower, borrower); // vault가 가지고있는 전체 돈보다 많이 가져가려고 하면 안됨

        eWETH.withdraw(maxWithdrawAmount, borrower, borrower);

        uint256 assetBalanceAfter = WETH.balanceOf(borrower);
        uint256 shareBalanceAfter = eWETH.balanceOf(borrower);

        assertEq(maxWithdrawAmount, assetBalanceAfter - assetBalanceBefore);
        assertEq(shareBalanceBefore - shareBalanceAfter, expectedBurnedShares);
    }

    function test_evc_maximum_withdraw() public {}

    function test_basic_redeem() public {}

    function test_maximum_redeem() public {}

    function test_evc_maximum_redeem() public {}
}
