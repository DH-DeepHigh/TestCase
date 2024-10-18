// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/interfaces/Exponential.sol";
import "../src/TestFile.sol";

contract CollateralSupplyTest is Test, TestUtils, Exponential, tools{
    address minter = address(this);
    uint mintAmount = 10 * 1e18;
    
    function setUp() public{
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
        deal(address(dai),address(this),mintAmount);
        dai.approve(address(cDai),type(uint).max);
    }

    function test_supplyCErc20_simple() public{
        cDai.mint(mintAmount);
        uint totalcDai = cDai.balanceOf(minter);
        
        Exp memory exchangeRate = Exp(cDai.exchangeRateCurrent());
        uint amount = div_(mintAmount,exchangeRate);
        assert(totalcDai == amount);

        
    }
    function test_supplyCEther_simple() public{
        cEther.mint{value: mintAmount}();
        uint totalcEther = cEther.balanceOf(minter); 

        Exp memory exchangeRate = Exp(cEther.exchangeRateCurrent());
        uint amount = div_(mintAmount,exchangeRate);
        assert(totalcEther == amount);
    }
    function test_supplyCEther_pause() public{
        set_pause();
        vm.expectRevert("mint is paused");
        cEther.mint{value : mintAmount}();
        
        set_unpause();
        cEther.mint{value : mintAmount}();

        assertGt(cEther.balanceOf(minter),0);
    }

    function test_supplyCErc20_pause() public{
        set_pause();
        vm.expectRevert("mint is paused");
        cDai.mint(mintAmount);
        
        set_unpause();
        cDai.mint(mintAmount);

        assertGt(cDai.balanceOf(minter),0);
    }
    function test_supply_marketList() public{
        /*
        Market list check
        mint call Sequence mint => mintInternal => mintFresh => mintAllowed
        */
        vm.startPrank(address(Not_registered_CToken));
        uint Errorcode =comptroller.mintAllowed(address(Not_registered_CToken),minter,mintAmount);
        vm.stopPrank();
        // Errorcode = MARKET_NOT_LISTED
        assertEq(Errorcode,9);
        
        vm.startPrank(address(cDai));
        Errorcode =comptroller.mintAllowed(address(cDai),minter,mintAmount);
        vm.stopPrank();
        // Errorcode =NO.ERROR
        assertEq(Errorcode, 0);
    }
}