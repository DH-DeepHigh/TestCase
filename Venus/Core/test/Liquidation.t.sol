// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/VenusUtils.sol";
import "../src/interface/Exponential.sol";
import "../src/testFile.sol";
import "../src/interface/TokenErrorReporter.sol";

contract LiquidationTest is Test, VenusUtils, Exponential, tools{
    address lender = address(this);
    address borrower = makeAddr("borrower");
    uint borrowAmount = 1000 * 1e18;
    uint supplyAmount = 10 * 1e18;

    function setUp() public{
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        vm.deal(borrower, supplyAmount);
        
        vm.startPrank(borrower);
        vBNB.mint{value : supplyAmount}();

        address[] memory vToken = new address[](1);
        vToken[0] = address(vBNB);
        comptroller.enterMarkets(vToken); 
        
        vDAI.borrow(borrowAmount);
        dai.approve(address(vDAI),type(uint).max);
        vm.stopPrank();
        dai.approve(address(liquidator),type(uint).max);

        deal(address(dai),lender,borrowAmount*2);
    }
    function test_liquidate_checkMarket() public {
        vm.expectRevert(abi.encodeWithSignature("MarketNotListed(address)", address(Not_registered_vToken)));
        liquidator.liquidateBorrow(address(vDAI), borrower, 1, Not_registered_vToken);
    }
    function test_liquidate_checkLTV() public{
        bytes memory Errorcode = abi.encodeWithSignature("LiquidationFailed(uint256)", 3);
        //Errorcode => INSUFFICIENT_SHORTFALL
        vm.expectRevert(Errorcode);
        liquidator.liquidateBorrow(address(vDAI), borrower, 1, vBNB);
    }
    
}