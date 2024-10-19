// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EVaultTestBase} from "./forkUtils/testBase/EVaultTestBase.sol";
import {Events} from "../src/EVault/shared/Events.sol";
import {SafeERC20Lib} from "../src/EVault/shared/lib/SafeERC20Lib.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";

import {console} from "forge-std/Test.sol";

import "../src/EVault/shared/types/Types.sol";
import "../src/EVault/shared/Constants.sol";

contract Liquidation is EVaultTestBase {
    using TypesLib for uint256;

    address lender;
    address borrower;
    address liquidator;

    function setUp() public override {
        super.setUp();
        cheat.createSelectFork("eth_mainnet", BLOCK_NUMBER);

        lender = makeAddr("lender");
        borrower = makeAddr("borrower");
        liquidator= makeAddr("liquidator"); 

        vm.startPrank(lender);
        deal(address(DAI), lender, type(uint256).max);
        DAI.approve(address(eDAI), type(uint256).max);
        eDAI.deposit(50_000 * 1e18, lender);

        vm.startPrank(borrower);
        deal(address(WETH), borrower, type(uint256).max);
        WETH.approve(address(eWETH), type(uint256).max);
        eWETH.deposit(10 * 1e18, borrower);

        vm.startPrank(liquidator);
        deal(address(DAI), liquidator, type(uint256).max);
        DAI.approve(address(eDAI), type(uint256).max);

        vm.stopPrank();
    }

    function test_liquidate_check_market() public {
        vm.startPrank(borrower);

        vm.expectRevert(Errors.E_ControllerDisabled.selector);
        eDAI.liquidate(borrower, address(eWETH), 1, 0);
    }

    function test_liquidation_no_selfLiquidation() public {
        vm.startPrank(borrower);
        evc.enableController(borrower, address(eDAI));

        vm.expectRevert(Errors.E_SelfLiquidation.selector);
        eDAI.liquidate(borrower, address(eWETH), 1, 0);
    }
}