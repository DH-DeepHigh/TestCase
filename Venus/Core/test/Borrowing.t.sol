// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/VenusUtils.sol";
import "../src/interface/Exponential.sol";
import "../src/testFile.sol";
import "../src/interface/TokenErrorReporter.sol";

contract BorrowingTest is Test, VenusUtils, Exponential, tools{
    address borrower = address(this);
    address lender = makeAddr("lender");
    
    uint borrowAmount = 1000 * 1e18;
    uint supplyAmount = 10* 1e18;
    
    function setUp() public{
        // Fork mainnet at block 43_056_300.
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        vBNB.mint{value : supplyAmount}();

        address[] memory vToken = new address[](1);
        vToken[0] = address(vBNB);
        comptroller.enterMarkets(vToken); 
        //--------------------------------------------------//
        deal(address(vBNB),lender,borrowAmount);
        
        vm.startPrank(lender);
        vToken[0] = address(vBNB);
        comptroller.enterMarkets(vToken); 
        
        //allow borrowBehalf
        comptroller.updateDelegate(borrower,true);
        vm.stopPrank();

    }
    function test_borrow_simple() public{
        vDAI.borrow(borrowAmount);
        assertEq(dai.balanceOf(borrower), borrowAmount);
    }
    function test_borrow_simple2() public {
        
        vDAI.borrowBehalf(lender, borrowAmount);

        assertEq(dai.balanceOf(borrower), borrowAmount);
        assertEq(vDAI.borrowBalanceCurrent(lender), borrowAmount);
    } 
    function test_borrow_checkMarket() public {
        /*
        borrow call Sequence borrow => borrowInternal => borrowFresh => borrowAllowed
        */
        vm.startPrank(address(Not_registered_vToken));
        vm.expectRevert("market not listed");
        comptroller.borrowAllowed(address(Not_registered_vToken),borrower,borrowAmount);
        vm.stopPrank();

        vm.startPrank(address(vDAI));
        comptroller.borrowAllowed(address(vDAI),borrower,borrowAmount);
        vm.stopPrank();
    }
    function test_borrow_checkMembership() public{   
        bool result=comptroller.checkMembership(borrower,address(vDAI));
        assertEq(result,false);
        
        vDAI.borrow(borrowAmount);
        
        result=comptroller.checkMembership(borrower,address(vDAI));
        assertEq(result,true);
    }
    function test_borrow_checkBorrowCap() public {
        deal(address(vBNB), borrower, 100000 * 1e18);
        uint totalBorrow = vDAI.totalBorrowsCurrent();
        uint borrowCap = comptroller.borrowCaps(address(vDAI));
        console.log(borrowCap);
        console.log(totalBorrow);

        require(borrowCap >= totalBorrow, "borrowCap is less than totalBorrow");

        uint gap = borrowCap - totalBorrow;

        vm.expectRevert("market borrow cap reached");
        vDAI.borrow(gap + 1);  

        // borrow limit
        vDAI.borrow(dai.balanceOf(address(vDAI)));
    }
    function test_borrow_checkLTV() public {
        uint amount = 5000 * 1e18;
        address[] memory market = new address[](1);
        market[0] = address(vDAI);

        comptroller.enterMarkets(market);
        (,,uint shortfall)=comptroller.getHypotheticalAccountLiquidity(borrower, address(vDAI), 0, amount);
        assertGt(shortfall,0);

        vm.expectRevert("math error");
        //return allowed => INSUFFICIENT_LIQUIDITY
        vDAI.borrow(amount);
        
        //success
        vDAI.borrow(borrowAmount);
    }
    function test_borrow_checkAccrueBlock() public{
        vDAI.borrow(borrowAmount);
        assertEq(vDAI.accrualBlockNumber(),block.number);
    }
    function testFail_borrow_checkAmount()public{
        //can't catch errorcode math error
        deal(address(vBNB),borrower, 100000 * 1e18);
        //vm.expectRevert("math error");
        vDAI.borrow(dai.balanceOf(address(vDAI))+1);
    
    }
    function test_borrow_checkOut() public{
        vDAI.borrow(borrowAmount);
        //return Errorcode
        uint Errorcode=comptroller.exitMarket(address(vDAI));
        //Errorcode => NONZERO_BORROW_BALANCE
        assertEq(Errorcode,12);
    } 
    function test_borrow_checkPause() public {
        Pause();
        vm.expectRevert("protocol is paused");
        vDAI.borrow(borrowAmount);

        unPause();
        vDAI.borrow(borrowAmount);

        assertEq(dai.balanceOf(borrower),borrowAmount);
    }  
    
    
    
}