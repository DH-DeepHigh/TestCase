// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/interfaces/Exponential.sol";
import "../src/TestFile.sol";

contract CollateralSupplyTest is Test, TestUtils, Exponential, tools{
    address lender = address(this);
    uint supplyAmount = 10 * 1e18;
    
    function setUp() public{
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
        deal(address(dai),address(this),supplyAmount);
        dai.approve(address(cDai),type(uint).max);
    }

    function test_supplyCErc20_simple() public{
        cDai.mint(supplyAmount);
        uint totalcDai = cDai.balanceOf(lender);
        
        Exp memory exchangeRate = Exp(cDai.exchangeRateCurrent());
        uint amount = div_(supplyAmount,exchangeRate);
        assert(totalcDai == amount);

        
    }
    function test_supplyCEther_simple() public{
        cEther.mint{value: supplyAmount}();
        uint totalcEther = cEther.balanceOf(lender); 

        Exp memory exchangeRate = Exp(cEther.exchangeRateCurrent());
        uint amount = div_(supplyAmount,exchangeRate);
        assert(totalcEther == amount);
    }
    function test_supplyCEther_pause() public{
        set_pause();
        vm.expectRevert("mint is paused");
        cEther.mint{value : supplyAmount}();
        
        set_unpause();
        cEther.mint{value : supplyAmount}();

        assertGt(cEther.balanceOf(lender),0);
    }

    function test_supplyCErc20_pause() public{
        set_pause();
        vm.expectRevert("mint is paused");
        cDai.mint(supplyAmount);
        
        set_unpause();
        cDai.mint(supplyAmount);

        assertGt(cDai.balanceOf(lender),0);
    }
    function test_supply_checkMarket() public{
        /*
        mint call Sequence mint => mintInternal => mintFresh => mintAllowed
        */
        vm.startPrank(address(Not_registered_cToken));
        uint Errorcode =comptroller.mintAllowed(address(Not_registered_cToken),lender,supplyAmount);
        vm.stopPrank();
        // Errorcode = MARKET_NOT_LISTED
        assertEq(Errorcode,9);
        
        vm.startPrank(address(cDai));
        Errorcode =comptroller.mintAllowed(address(cDai),lender,supplyAmount);
        vm.stopPrank();
        // Errorcode =NO.ERROR
        assertEq(Errorcode, 0);
    }
}