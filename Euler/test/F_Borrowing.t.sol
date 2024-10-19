// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EVaultTestBase} from "./forkutils/testBase/EVaultTestBase.sol";
import {Events} from "../src/EVault/shared/Events.sol";
import {SafeERC20Lib} from "../src/EVault/shared/lib/SafeERC20Lib.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {IRMMax} from "./forkUtils/mocks/IRMMax.sol";
import {IRMTestFixed} from "./forkUtils/mocks/IRMTestFixed.sol";
import {IRMFailed} from "./forkUtils/mocks/IRMFailed.sol";
import {IRMOverBound} from "./forkUtils/mocks/IRMOverBound.sol";
import {Events as EVCEvents} from "ethereum-vault-connector/Events.sol";
import "forge-std/Test.sol";

import "../src/EVault/shared/types/Types.sol";
import "../src/EVault/shared/Constants.sol";

contract Borrowing is EVaultTestBase {
    using TypesLib for uint256;

    address lender;
    address borrower1;
    address borrower2;

    function setUp() public override {
        super.setUp();
        cheat.createSelectFork("eth_mainnet", BLOCK_NUMBER);

        lender = makeAddr("lender");
        borrower1 = makeAddr("borrower1");
        borrower2 = makeAddr("borrower2");

        startHoax(lender);
        // deal(address(WETH), lender, type(uint256).max);
        deal(address(DAI), lender, type(uint256).max);
        DAI.approve(address(eDAI), type(uint256).max);
        eDAI.deposit(50_000 * 1e18, lender);
        
        startHoax(borrower1);
        deal(address(WETH), borrower1, type(uint256).max);
        // deal(address(DAI), borrower1, type(uint256).max);
        WETH.approve(address(eWETH), type(uint256).max);
        eWETH.deposit(10 * 1e18, borrower1);      

        vm.stopPrank();  
    }

    function test_borrow_simple() public {
        uint256 borrowAmount = 10_000 * 1e18;

        uint256 totalBorrowsBefore = eDAI.totalBorrows();
        uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();
        
        vm.startPrank(borrower1);

        evc.enableController(borrower1, address(eDAI));
        evc.enableCollateral(borrower1, address(eWETH));

        eDAI.borrow(borrowAmount, borrower1);

        assertEq(DAI.balanceOf(borrower1), borrowAmount);
        assertEq(eDAI.debtOf(borrower1), borrowAmount);
        assertEq(eDAI.debtOfExact(borrower1), borrowAmount << INTERNAL_DEBT_PRECISION_SHIFT);
        assertEq(eDAI.totalBorrows() - totalBorrowsBefore, borrowAmount);
        assertEq(eDAI.totalBorrowsExact() - totalBorrowsExactBefore, borrowAmount << INTERNAL_DEBT_PRECISION_SHIFT);
    }

    function test_borrow_market_exist() public {
        IEVault eVault = IEVault(makeAddr("eVault"));
        
        vm.startPrank(borrower1);

        evc.enableCollateral(borrower1, address(eWETH));
        vm.expectRevert(Errors.EVC_EmptyError.selector);
        evc.enableController(borrower1, address(eVault)); // borrow를 하려면, controller로 설정이 되어야 하는데, 이 부분에서 막힘.        
    }
    
    function test_borrow_registered_asset() public {
        uint256 borrowAmount = 10_000 * 1e18;
        uint256 totalBorrowsBefore = eDAI.totalBorrows();
        uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();

        vm.startPrank(borrower1);

        evc.enableCollateral(borrower1, address(eWETH));

        // if eDAI not enabled as controller, borrower cannot borrow DAI
        vm.expectRevert(Errors.E_ControllerDisabled.selector);
        eDAI.borrow(borrowAmount, borrower1);

        evc.enableController(borrower1, address(eDAI));
        eDAI.borrow(borrowAmount, borrower1);
        
        assertEq(DAI.balanceOf(borrower1), borrowAmount);
        assertEq(eDAI.debtOf(borrower1), borrowAmount);
        assertEq(eDAI.debtOfExact(borrower1), borrowAmount << INTERNAL_DEBT_PRECISION_SHIFT);
        assertEq(eDAI.totalBorrows() - totalBorrowsBefore, borrowAmount);
        assertEq(eDAI.totalBorrowsExact() - totalBorrowsExactBefore, borrowAmount << INTERNAL_DEBT_PRECISION_SHIFT);
    }

    function test_borrow_registered_collateral() public {
        uint256 borrowAmount = 10_000 * 1e18;
        uint256 totalBorrowsBefore = eDAI.totalBorrows();
        uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();

        vm.startPrank(borrower1);

        evc.enableController(borrower1, address(eDAI));

        // if eWETH not enabled as collateral, borrower cannot use WETH as collateral
        vm.expectRevert(Errors.E_AccountLiquidity.selector);
        eDAI.borrow(borrowAmount, borrower1);

        evc.enableCollateral(borrower1, address(eWETH));
        eDAI.borrow(borrowAmount, borrower1);
        
        assertEq(DAI.balanceOf(borrower1), borrowAmount);
        assertEq(eDAI.debtOf(borrower1), borrowAmount);
        assertEq(eDAI.debtOfExact(borrower1), borrowAmount << INTERNAL_DEBT_PRECISION_SHIFT);
        assertEq(eDAI.totalBorrows() - totalBorrowsBefore, borrowAmount);
        assertEq(eDAI.totalBorrowsExact() - totalBorrowsExactBefore, borrowAmount << INTERNAL_DEBT_PRECISION_SHIFT);
    }

    function test_borrow_below_borrow_cap() public { // 미완성
        // (uint256 eDAISupplyCap, uint256 eDAIBorrowCap) = eDAI.caps();
        // (uint256 eWETHSupplyCap, ) = eWETH.caps();
        // console.log(eDAISupplyCap, eDAIBorrowCap, eWETHSupplyCap);

        // uint256 totalBorrowsBefore = eDAI.totalBorrows();
        // uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();
        
        // vm.prank(lender);
        // eDAI.deposit(eDAISupplyCap - eDAI.totalSupply(), lender);

        // vm.startPrank(borrower1);
        
        // eWETH.deposit(eWETHSupplyCap - eWETH.totalSupply(), borrower1);

        // evc.enableController(borrower1, address(eDAI));
        // evc.enableCollateral(borrower1, address(eWETH));

        // eDAI.borrow(eDAIBorrowCap - totalBorrowsBefore, borrower1);
    }

    function test_borrow_liquidity_check() public {
        uint256 totalBorrowsBefore = eDAI.totalBorrows();
        uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();
    
        vm.startPrank(borrower1);
        
        evc.enableController(borrower1, address(eDAI));
        evc.enableCollateral(borrower1, address(eWETH));

        uint256 collateralValue = calculateCollateralPrices(address(eDAI), borrower1, true);
        (, uint256 maxBorrow) = oracle.getQuotes(collateralValue, unitOfAccount, eDAI.asset());
        
        vm.expectRevert(Errors.E_AccountLiquidity.selector);
        eDAI.borrow(maxBorrow + 1, borrower1);

        eDAI.borrow(maxBorrow, borrower1);

        assertEq(DAI.balanceOf(borrower1), maxBorrow);
        assertEq(eDAI.debtOf(borrower1), maxBorrow);
        assertEq(eDAI.debtOfExact(borrower1), maxBorrow << INTERNAL_DEBT_PRECISION_SHIFT);
        assertEq(eDAI.totalBorrows() - totalBorrowsBefore, maxBorrow);
        assertEq(eDAI.totalBorrowsExact() - totalBorrowsExactBefore, maxBorrow << INTERNAL_DEBT_PRECISION_SHIFT);
    }

    function test_borrow_over_market_balance() public {
        uint256 marketBalance = eDAI.cash();
        uint256 totalBorrowsBefore = eDAI.totalBorrows();
        uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();

        vm.startPrank(borrower1);
        
        eWETH.deposit(10_000 * 1e18, borrower1);

        evc.enableController(borrower1, address(eDAI));
        evc.enableCollateral(borrower1, address(eWETH));

        vm.expectRevert(Errors.E_InsufficientCash.selector);
        eDAI.borrow(marketBalance + 1, borrower1); // cannot borrow more than market balance

        eDAI.borrow(marketBalance, borrower1);

        assertEq(DAI.balanceOf(borrower1), marketBalance);
        assertEq(eDAI.debtOf(borrower1), marketBalance);
        assertEq(eDAI.debtOfExact(borrower1), marketBalance << INTERNAL_DEBT_PRECISION_SHIFT);
        assertEq(eDAI.totalBorrows() - totalBorrowsBefore, marketBalance);
        assertEq(eDAI.totalBorrowsExact() - totalBorrowsExactBefore, marketBalance << INTERNAL_DEBT_PRECISION_SHIFT); 
    }

    function test_borrow_below_total_balance() public {
        uint256 marketBalance = DAI.balanceOf(address(eDAI));

        vm.startPrank(borrower1);
        eWETH.deposit(100 * 1e18, borrower1);      

        evc.enableController(borrower1, address(eDAI));
        evc.enableCollateral(borrower1, address(eWETH));

        vm.expectRevert(Errors.E_InsufficientCash.selector);
        eDAI.borrow(marketBalance + 1, borrower1);

        eDAI.borrow(marketBalance, borrower1);
    }
}
