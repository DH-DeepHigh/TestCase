// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/interfaces/Exponential.sol";
import "../src/TestFile.sol";
import "../src/interfaces/TokenErrorReporter.sol";

contract BorrowingTest is Test, TestUtils, Exponential, tools{
    address borrower = address(this);
    uint borrowAmount = 10000 * 1e18;
    uint mintAmount = 10* 1e18;
    
    function setUp() public{
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
        cEther.mint{value : mintAmount}();

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        comptroller.enterMarkets(cTokens); 
    }
    function test_borrow_simple() public{
        address[] memory assetsIn = comptroller.getAssetsIn(borrower);
        assertEq(assetsIn[0], address(cEther));
        
        cDai.borrow(borrowAmount);
        assertEq(dai.balanceOf(borrower), borrowAmount);
    }
    function test_borrow_checkPause() public {
        set_pause();
        vm.expectRevert("borrow is paused");
        cDai.borrow(borrowAmount);

        set_unpause();
        cDai.borrow(borrowAmount);
        assertEq(dai.balanceOf(borrower), borrowAmount);
    }

    function test_borrow_checkMarketList() public{
        /*
        Market list check
        mint call Sequence mint => mintInternal => mintFresh => mintAllowed
        */
        vm.startPrank(address(Not_registered_CToken));
        uint Errorcode =comptroller.borrowAllowed(address(Not_registered_CToken),borrower,borrowAmount);
        vm.stopPrank();
        // Errorcode = MARKET_NOT_LISTED
        assertEq(Errorcode,9);

        vm.startPrank(address(cDai));
        Errorcode =comptroller.borrowAllowed(address(cDai),borrower,borrowAmount);
        vm.stopPrank();
        // Errorcode =NO.ERROR
        assertEq(Errorcode, 0);
    }
    function test_borrow_checkUnderlyingPrice() public{
        //set underlying price zero  & Previous underlying price
        uint amount=set_borrow_price_zero();

        bytes memory errorcode = abi.encodeWithSignature("BorrowComptrollerRejection(uint256)", 13);
        vm.expectRevert(errorcode);
        
        cDai.borrow(borrowAmount);

        set_borrow_price_rollback(amount);
        cDai.borrow(borrowAmount);

        assertEq(dai.balanceOf(borrower),borrowAmount);
    }
    function test_borrow_checkMembership() public{   
        bool result=comptroller.checkMembership(borrower,address(cDai));
        assertEq(result,false);
        
        cDai.borrow(borrowAmount);
        
        result=comptroller.checkMembership(borrower,address(cDai));
        assertEq(result,true);
    }
    function test_borrow_checkBorrowCap() public {
        uint totalBorrow=cDai.totalBorrowsCurrent();
        uint borrowCap = 80000000 * 1e18; 
        
        vm.expectRevert("market borrow cap reached");
        cDai.borrow(borrowCap - totalBorrow);
    }
    function test_borrow_overLTV() public {
        uint amount = 20000 * 1e18;
        address[] memory market = new address[](1);
        market[0] = address(cDai);

        comptroller.enterMarkets(market);

        (,,uint shortfall)=comptroller.getHypotheticalAccountLiquidity(borrower,address(cDai),0,amount);
        assertGt(shortfall, 0);

        bytes memory errorcode = abi.encodeWithSignature("BorrowComptrollerRejection(uint256)", 4);
        vm.expectRevert(errorcode);
        cDai.borrow(amount);
    }
    function test_borrow_checkaccrueBlock() public {
        cDai.borrow(borrowAmount);
        assertEq(cDai.accrualBlockNumber(),block.number);
    }
    function testFail_Borrow_checkAmount()public{
        //can't catch errorcode BorrowCashNotAvailable()
        cEther.mint{value : borrower.balance}();
        bytes memory errorcode = abi.encodeWithSignature("BorrowCashNotAvailable()");
        cDai.borrow(dai.balanceOf(address(cDai))+1);
    }
    
}