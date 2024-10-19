// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/VenusUtils.sol";
import "../src/interface/Exponential.sol";
import "../src/testFile.sol";
import "../src/interface/TokenErrorReporter.sol";

contract CollateralSupplyTest is Test, VenusUtils, Exponential, tools{
    address lender = address(this);
    address user = makeAddr("user");
    uint supplyAmount = 10 * 1e18;
    
    function setUp() public{
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        vm.deal(lender,supplyAmount);
        deal(address(dai),lender,supplyAmount);
        dai.approve(address(vDAI),type(uint).max);
    }

    function test_supply_simple() public {
        vBNB.mint{value : supplyAmount}();
        
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vBNB);
        comptroller.enterMarkets(vTokens);

        (, uint collateralFactorMantissa) = comptroller.markets(address(vBNB));

        (, uint liquidity,) = comptroller.getAccountLiquidity(lender);
        liquidity = liquidity / supplyAmount;

        uint price = oracle.getUnderlyingPrice(address(vBNB));

        uint expectedLiquidity = (price * collateralFactorMantissa / 1e18) / 1e18;
        assertEq(liquidity, expectedLiquidity);
    }
    function test_supply_simple2() public {
        vDAI.mintBehalf(user,supplyAmount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vDAI);
        comptroller.enterMarkets(vTokens);

        (, uint collateralFactorMantissa) = comptroller.markets(address(vDAI));

        (, uint liquidity,) = comptroller.getAccountLiquidity(user);
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vDAI));

        uint expectedLiquidity = (price * collateralFactorMantissa / 1e18) / 1e18;
        assertEq(liquidity, expectedLiquidity);
    }

    function test_supply_cehckPause() public{
        Pause();
        vm.expectRevert("protocol is paused");
        vBNB.mint{value : supplyAmount}();
        
        unPause();
        vBNB.mint{value : supplyAmount}();

        assertGt(vBNB.balanceOf(lender),0);
    }

    function test_supply_checkMarket() public{
        /*
        mint call Sequence mint => mintInternal => mintFresh => mintAllowed
        */
        vm.startPrank(address(Not_registered_vToken));
        vm.expectRevert("market not listed");
        comptroller.mintAllowed(address(Not_registered_vToken),lender,supplyAmount);
        vm.stopPrank();
        
        vm.startPrank(address(vDAI));
        uint Errorcode =comptroller.mintAllowed(address(vDAI),lender,supplyAmount);
        vm.stopPrank();
        // Errorcode =NO.ERROR
        assertEq(Errorcode, 0);
    }
    function test_supply_checkAccrueBlock() public{
        vBNB.mint{value : supplyAmount}();
        assertEq(vBNB.accrualBlockNumber(),block.number);
    }
}