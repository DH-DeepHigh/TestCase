// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EVaultTestBase} from "../deployUtils/testBase/EVaultTestBase.sol";
import {Events} from "../../src/EVault/shared/Events.sol";
import {SafeERC20Lib} from "../../src/EVault/shared/lib/SafeERC20Lib.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {IEVault} from "../../src/EVault/IEVault.sol";
import {TestERC20} from "../deployUtils/mocks/TestERC20.sol";
import {IRMTestZero} from "../deployUtils/mocks/IRMTestZero.sol";
import {Errors} from "../../src/EVault/shared/Errors.sol";

import "../../src/EVault/shared/types/Types.sol";
import "../../src/EVault/shared/Constants.sol";

import "forge-std/Test.sol";

contract Test_CollateralWithdraw is EVaultTestBase {
    using TypesLib for uint256;

    address lender;
    address borrower;

    TestERC20 assetTST3;
    IEVault public eTST3;

    function setUp() public override {
        super.setUp();

        lender = makeAddr("lender");
        borrower = makeAddr("borrower");

        assetTST3 = new TestERC20("Test TST 3", "TST3", 18, false);
        eTST3 = IEVault(
            factory.createProxy(address(0), true, abi.encodePacked(address(assetTST3), address(oracle), unitOfAccount))
        );
        eTST3.setHookConfig(address(0), 0);

        eTST.setInterestRateModel(address(new IRMTestZero()));
        eTST2.setInterestRateModel(address(new IRMTestZero()));
        eTST3.setInterestRateModel(address(new IRMTestZero()));

        oracle.setPrice(address(eTST), unitOfAccount, 2.2e18);
        oracle.setPrice(address(eTST2), unitOfAccount, 0.4e18);
        oracle.setPrice(address(eTST3), unitOfAccount, 2.2e18);

        eTST.setLTV(address(eTST2), 0.3e4, 0.3e4, 0);
        
        // lender 
        startHoax(lender);
        assetTST.mint(lender, type(uint256).max);
        assetTST.approve(address(eTST), type(uint256).max);
        eTST.deposit(10e18, lender);

        assetTST3.mint(lender, 200e18);
        assetTST3.approve(address(eTST3), type(uint256).max);
        eTST3.deposit(100e18, lender);

        // borrower  
        startHoax(borrower);
        assetTST2.mint(borrower, type(uint256).max);
        assetTST2.approve(address(eTST2), type(uint256).max);
        eTST2.deposit(10e18, borrower);

        vm.stopPrank();
    }

    function test_basic_withdraw() public {
        uint256 withdrawAmount = 100e18;
        uint256 expectedBurnedSharess = eTST2.previewWithdraw(withdrawAmount);

        
    }

    function test_maximum_withdraw() public {
        uint256 maxWithdrawAmount = eTST2.maxWithdraw(borrower); // withdraw될 asset의 총량
        uint256 expectedBurnedShares = eTST2.previewWithdraw(maxWithdrawAmount); // withdraw될 easset의 총량
        
        uint256 assetBalanceBefore = assetTST2.balanceOf(borrower); // deposit상태에서 asset의 잔액 
        uint256 shareBalanceBefore = eTST2.balanceOf(borrower); //  '' eTST의 잔액
        
        startHoax(borrower);
        vm.expectRevert(Errors.E_InsufficientCash.selector);
        eTST2.withdraw(maxWithdrawAmount + 1, borrower, borrower); // 더 많이 하려고 하면 못함

        eTST2.withdraw(maxWithdrawAmount, borrower, borrower);

        uint256 assetBalanceAfter = assetTST2.balanceOf(borrower);
        uint256 shareBalanceAfter = eTST2.balanceOf(borrower);
        assertEq(maxWithdrawAmount, assetBalanceAfter - assetBalanceBefore);
        assertEq(shareBalanceBefore - shareBalanceAfter, expectedBurnedShares);
    }

    function test_evc_maximum_withdraw() public {}

    function test_basic_redeem() public {}

    function test_maximum_redeem() public {}

    function test_evc_maximum_redeem() public {}
}
