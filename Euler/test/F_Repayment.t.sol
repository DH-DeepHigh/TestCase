// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {EVaultTestBase} from "./forkUtils/testBase/EVaultTestBase.sol";
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

contract Test_CollateralWithdraw is EVaultTestBase {  
    using stdStorage for StdStorage;
    using TypesLib for uint256;

    address lender;
    address borrower;

    function setUp() public override {
        super.setUp();
        cheat.createSelectFork("eth_mainnet", BLOCK_NUMBER);

        lender = makeAddr("lender");
        borrower = makeAddr("borrower"); 

        vm.startPrank(lender);
        deal(address(DAI), lender, type(uint256).max);
        DAI.approve(address(eDAI), type(uint256).max);
        eDAI.deposit(10_000 * 1e18, lender);

        vm.startPrank(borrower);
        deal(address(WETH), borrower, type(uint256).max);
        WETH.approve(address(eWETH), type(uint256).max);
        eWETH.deposit(10 * 1e18, borrower);
    }

    function test_repay_simple() public {
        uint256 borrowAmount = 10_000 * 1e18;

        uint256 totalBorrowsBefore = eDAI.totalBorrows();
        uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();
        
        vm.startPrank(borrower);

        evc.enableController(borrower, address(eDAI));
        evc.enableCollateral(borrower, address(eWETH));

        // borrow
        eDAI.borrow(borrowAmount, borrower);

        assertEq(DAI.balanceOf(borrower), borrowAmount);

        // repay
        DAI.approve(address(eDAI), type(uint256).max);
        eDAI.repay(type(uint256).max, borrower);

        assertEq(DAI.balanceOf(borrower), 0);

        evc.disableCollateral(borrower, address(eWETH));
        assertEq(evc.getCollaterals(borrower).length, 0);

        eDAI.disableController();
        assertEq(evc.getControllers(borrower).length, 0);
    }

    function test_repay_cannot_unlistable_unhealthy() public {
        uint256 borrowAmount = 10_000 * 1e18;

        uint256 totalBorrowsBefore = eDAI.totalBorrows();
        uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();
        
        vm.startPrank(borrower);

        evc.enableController(borrower, address(eDAI));
        evc.enableCollateral(borrower, address(eWETH));

        // borrow
        eDAI.borrow(borrowAmount, borrower);

        assertEq(DAI.balanceOf(borrower), borrowAmount);

        // repay (unhealthy)
        DAI.approve(address(eDAI), type(uint256).max);
        eDAI.repay(borrowAmount - 1, borrower);

        assertEq(DAI.balanceOf(borrower), 1);

        vm.expectRevert();
        evc.disableCollateral(borrower, address(eWETH));

        vm.expectRevert();
        eDAI.disableController();

        // repay all
        eDAI.repay(1, borrower);
        assertEq(DAI.balanceOf(borrower), 0);

        evc.disableCollateral(borrower, address(eWETH));
        assertEq(evc.getCollaterals(borrower).length, 0);
        
        eDAI.disableController();
        assertEq(evc.getControllers(borrower).length, 0);
    }

    function test_repay_cannot_repay_overDebt() public {
        uint256 borrowAmount = 10_000 * 1e18;

        uint256 totalBorrowsBefore = eDAI.totalBorrows();
        uint256 totalBorrowsExactBefore = eDAI.totalBorrowsExact();
        
        vm.startPrank(borrower);

        evc.enableController(borrower, address(eDAI));
        evc.enableCollateral(borrower, address(eWETH));

        // borrow
        eDAI.borrow(borrowAmount, borrower);

        assertEq(DAI.balanceOf(borrower), borrowAmount);

        // repay
        deal(address(DAI), borrower, type(uint256).max);

        DAI.approve(address(eDAI), type(uint256).max);

        vm.expectRevert(Errors.E_RepayTooMuch.selector);
        eDAI.repay(borrowAmount + 1, borrower);

        // nice repay
        eDAI.repay(borrowAmount, borrower);

        evc.disableCollateral(borrower, address(eWETH));
        assertEq(evc.getCollaterals(borrower).length, 0);
        
        eDAI.disableController();
        assertEq(evc.getControllers(borrower).length, 0);
    }
}