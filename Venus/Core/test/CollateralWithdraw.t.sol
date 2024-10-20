// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/VenusUtils.sol";
import "../src/interface/Exponential.sol";
import "../src/testFile.sol";
import "../src/interface/TokenErrorReporter.sol";

contract CollateralWithdrawTest is Test, VenusUtils, Exponential, tools{
    address lender = address(this);
    address user = makeAddr("user");
    uint supplyAmount = 10 * 1e18;
    
    function setUp() public{
        // Fork mainnet at block 43_056_300.
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);    
        vm.deal(lender,supplyAmount);
        vBNB.mint{value : supplyAmount}();

        address[] memory vToken = new address[](1);
        vToken[0] = address(vBNB);
        comptroller.enterMarkets(vToken); 

    }
    function test_withdraw_simpleToken() public {
        uint exchangeRate = vBNB.exchangeRateCurrent();
        uint vBNBBalance = vBNB.balanceOf(address(this));

        // We get the amount of vBNB that we should have.
        uint mintTokens = supplyAmount * 1e18 / exchangeRate;
        assertEq(vBNBBalance, mintTokens);

        vm.roll(block.number + 1);

        require(vBNB.redeem(vBNB.balanceOf(address(this))) == 0, "redeem failed");
        assertEq(vBNB.balanceOf(address(this)), 0);
        
        //should have more eth with 1 block of interests.
        assertGt(address(this).balance , supplyAmount);
    }
    function test_withdraw_simpleUnderlying() public{
        uint beforeAmount = vBNB.balanceOf(address(this));
        vm.roll(block.number + 1);

        vBNB.redeemUnderlying(supplyAmount);
        assertEq(address(this).balance,supplyAmount);
        
        //calculation underlying amount
        uint exchangeRate = vBNB.exchangeRateCurrent();
        uint calc = supplyAmount * 1e18/exchangeRate;
        uint afterAmount = vBNB.balanceOf(address(this));
        assertEq(afterAmount, beforeAmount-calc);
    }
    function test_withdraw_checkMarket() public{
        /*
        withdraw call Sequence redeem/redeemUnderlying => redeemInternal/redeemUnderlyingInternal => redeemFresh => redeemAllowed
        */
        vm.startPrank(address(Not_registered_vToken));
        vm.expectRevert("market not listed");
        comptroller.redeemAllowed(address(Not_registered_vToken),lender,supplyAmount);
        vm.stopPrank();

        vm.startPrank(address(vDAI));
        uint Errorcode =comptroller.redeemAllowed(address(vDAI),lender,supplyAmount);
        vm.stopPrank();
        // Errorcode =NO.ERROR
        assertEq(Errorcode, 0);
    }
    function test_withdraw_checkLTV() public {
        uint amount = vBNB.balanceOf(lender);

        //over LTV
        (,,uint shortfall)=comptroller.getHypotheticalAccountLiquidity(lender,address(vBNB),amount+1,0);

        assertGt(shortfall,0);

        //return Errorcode
        uint Errorcode = vBNB.redeem(vBNB.balanceOf(lender)+1);
        //Errorcode =>INSUFFICIENT_SHORTFALL
        assertEq(Errorcode, 3);
        
        //return Errorcode
        Errorcode = vBNB.redeemUnderlying(supplyAmount + 1e18);
        //Errorcode =>INSUFFICIENT_SHORTFALL
        assertEq(Errorcode,3);
    }
    function test_withdraw_checkOut() public {
        assertEq(vBNB.borrowBalanceCurrent(lender),0);
    
        vDAI.borrow(1e18);
        uint Errorcode=comptroller.exitMarket(address(vBNB));
        //Errorcode => REJECTION 
        assertEq(Errorcode, 14);
    }
    
    function test_withdraw_checkAccrueBlock() public {
        vBNB.redeem(vBNB.balanceOf(lender));
        assertEq(vBNB.accrualBlockNumber(),block.number);
    }
    function test_withdraw_checkAmount() public {
        deal(address(vBNB),lender,10000*1e18);

        uint exchangeRate = vBNB.exchangeRateCurrent();
        uint totalBalance = address(vBNB).balance;
        uint calcBalance =totalBalance/(exchangeRate /1e18);
        
        //return Errorcode
        uint Errorcode=vBNB.redeem(calcBalance + 1);
        //Errorcode => REJECTION
        assertEq(Errorcode,14);
        
        //return Errorcode
        Errorcode = vBNB.redeemUnderlying(totalBalance+1);
        //Errorcode => REJECTION
        assertEq(Errorcode,14);
    }
    
    receive() payable external{}
}