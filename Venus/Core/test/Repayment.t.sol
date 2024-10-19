// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/VenusUtils.sol";
import "../src/interface/Exponential.sol";
import "../src/testFile.sol";
import "../src/interface/TokenErrorReporter.sol";

contract RepaymentTest is Test, VenusUtils, Exponential, tools{
    address borrower = address(this);
    address lender = makeAddr("lender");
    uint borrowAmount = 1000 * 1e18;
    uint supplyAmount = 10 * 1e18;
    
    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        vBNB.mint{value : supplyAmount}();

        address[] memory vToken = new address[](1);
        vToken[0] = address(vBNB);
        comptroller.enterMarkets(vToken); 
        vDAI.borrow(borrowAmount);
        dai.approve(address(vDAI),type(uint).max);

    //---------------------------------------------------//
        
        deal(address(dai),lender,borrowAmount * 2);
        vm.startPrank(lender);
        dai.approve(address(vDAI),type(uint).max);
        vToken[0] = address(vDAI);
        comptroller.enterMarkets(vToken);
        vm.stopPrank();
    }
         function test_repay_simpleBehalf() public {
        vm.roll(block.number + 3);
        uint beforeBalance = dai.balanceOf(lender);
        
        vm.startPrank(lender);
        uint repayAmount=vDAI.borrowBalanceCurrent(borrower);
        //borrowAmount + 3 block interest
        vDAI.repayBorrowBehalf(borrower,repayAmount);
        vm.stopPrank();

        uint afterBalance = dai.balanceOf(lender);
        assertEq(afterBalance,beforeBalance -repayAmount);
    }
    function test_repay_simple() public {
        vm.roll(block.number + 3);
        uint repayAmount=vDAI.borrowBalanceCurrent(borrower);
        deal(address(dai),borrower, repayAmount); 

        vDAI.repayBorrow(repayAmount);
        
        assertEq(vDAI.balanceOf(borrower),0);
    }

    function test_repay_checkMarket() public{
        /*
        repayBorrow call Sequence repayBorrow => repayBorrowInternal => repayBorrowFresh => repayBorrowAllowed
        */
        vm.startPrank(address(Not_registered_vToken));
        vm.expectRevert("market not listed");
        comptroller.repayBorrowAllowed(address(Not_registered_vToken),borrower,borrower,borrowAmount);
        vm.stopPrank();

        vm.startPrank(address(vDAI));
        uint Errorcode =comptroller.repayBorrowAllowed(address(vDAI),borrower,borrower,borrowAmount);
        vm.stopPrank();
        // Errorcode =NO.ERROR
        assertEq(Errorcode, 0);
    }
    function test_repay_checkAccrueBlock() public{
        vDAI.repayBorrow(borrowAmount);
        assertEq(vDAI.accrualBlockNumber(),block.number);
    }
    function test_repay_checkOut() public{
        //return Errorcode
        uint Errorcode = comptroller.exitMarket(address(vDAI));
        // Errorcode => NONZERO_BORROW_BALANCE
        assertEq(Errorcode,12);
        
        //repay BorrowAmount
        vDAI.repayBorrow(borrowAmount);
        Errorcode = comptroller.exitMarket(address(vDAI));
        //Errorcode => NO.Error
        assertEq(Errorcode,0);
    }
    function test_repay_checkOut2() public{
        //return Errorcode
        uint Errorcode = comptroller.exitMarket(address(vDAI));
        // Errorcode => NONZERO_BORROW_BALANCE
        assertEq(Errorcode,12);
        
        //repay BorrowAmount
        vm.startPrank(lender);
        vDAI.repayBorrowBehalf(borrower, borrowAmount);
        vm.stopPrank();
        
        Errorcode = comptroller.exitMarket(address(vDAI));
        //Errorcode => NO.Error
        assertEq(Errorcode,0);
    }
    
    function test_repay_checkAmount() public {
        deal(address(dai),borrower,borrowAmount * 2);
        vm.expectRevert("math error");
        vDAI.repayBorrow(borrowAmount + 1);

        vm.startPrank(lender);
        vm.expectRevert("math error");
        vDAI.repayBorrowBehalf(borrower, borrowAmount+1);
        vm.stopPrank();
    }

}