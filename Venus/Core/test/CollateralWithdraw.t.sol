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
        // Fork mainnet at block 20_941_968.
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
    receive() payable external{}
}