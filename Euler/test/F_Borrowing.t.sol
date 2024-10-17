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
        vm.startPrank(borrower1);

        uint256 totalBorrowsBefore = eDAI.totalBorrows();
        uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();

        evc.enableController(borrower1, address(eDAI));
        evc.enableCollateral(borrower1, address(eWETH));

        eDAI.borrow(borrowAmount, borrower1);

        assertEq(DAI.balanceOf(borrower1), borrowAmount);
        assertEq(eDAI.debtOf(borrower1), borrowAmount);
        assertEq(eDAI.debtOfExact(borrower1), borrowAmount << INTERNAL_DEBT_PRECISION_SHIFT);
        assertEq(eDAI.totalBorrows() - totalBorrowsBefore, borrowAmount);
        assertEq(eDAI.totalBorrowsExact() - totalBorrowsExactBefore, borrowAmount << INTERNAL_DEBT_PRECISION_SHIFT);
    }

    function test_borrow_market_exist() public { // 아직 미완성입니다.
        IEVault eVault = IEVault(makeAddr("eVault"));
        
        vm.startPrank(borrower1);
        
        uint256 borrowAmount = 10_000 * 1e18;
        uint256 totalBorrowsBefore = eDAI.totalBorrows();
        uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();

        evc.enableCollateral(borrower1, address(eWETH));
        vm.expectRevert(Errors.EVC_EmptyError.selector);
        evc.enableController(borrower1, address(eVault));
        
        
        evc.call(address(eVault), borrower1, 0, abi.encodeWithSelector(eVault.borrow.selector, borrowAmount, borrower1));
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
        uint256 borrowAmount = 10000e18;
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

}
