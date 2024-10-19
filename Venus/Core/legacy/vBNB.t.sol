// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "../src/VenusUtils.sol";

/// @notice Example contract that calculates the account liquidity.
contract vBNB_Test is Test, VenusUtils {
    address user =address(0x1234);
    function setUp() public {
        // Fork mainnet at block 43_056_300.
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        vm.deal(user,1e18);
    }
    function test_mint() public {
        vBNB.mint{value : 1e18}();
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vBNB);
        comptroller.enterMarkets(vTokens);

        (, uint collateralFactorMantissa) = comptroller.markets(address(vBNB));

        (, uint liquidity,) = comptroller.getAccountLiquidity(address(this));
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vBNB));

        uint expectedLiquidity = (price * collateralFactorMantissa / 1e18) / 1e18;
        assertEq(liquidity, expectedLiquidity);
    }
    function test_mintBehalf() public {
        vBNB.mintBehalf{value : 1e18}(address(this));
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vBNB);
        comptroller.enterMarkets(vTokens);

        (, uint collateralFactorMantissa) = comptroller.markets(address(vBNB));

        (, uint liquidity,) = comptroller.getAccountLiquidity(address(this));
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vBNB));

        uint expectedLiquidity = (price * collateralFactorMantissa / 1e18) / 1e18;
        assertEq(liquidity, expectedLiquidity);
    }

    function test_borrow() public {
        vBNB.mint{value : 1e18}();
        
        //enter vBNB market
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vBNB);
        comptroller.enterMarkets(vTokens); 
        
        //check
        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn[0], address(vBNB));

        //borrow usdc 100
        uint borrowAmount = 100 * 1e18;
        vUSDC.borrow(borrowAmount);

        assertEq(usdc.balanceOf(address(this)), borrowAmount);
    }
    function test_borrowBehalf() public {
        
        vm.startPrank(user);
        vBNB.mint{value : 1e18}();
        
        //enter vBNB market
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vBNB);
        comptroller.enterMarkets(vTokens); 
        
        //check
        address[] memory assetsIn = comptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vBNB));
        
        //allow borrowBehalf
        comptroller.updateDelegate(address(this),true);
        vm.stopPrank();
        
        //borrow usdc 100
        uint borrowAmount = 100 * 1e18;
        vUSDC.borrowBehalf(user, borrowAmount);

        assertEq(usdc.balanceOf(address(this)), borrowAmount);
        assertEq(vUSDC.borrowBalanceCurrent(user), borrowAmount);
    }   
    function test_repay() public {
        vBNB.mint{value : 1e18}();
        
        //enter vBNB market
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vBNB);
        comptroller.enterMarkets(vTokens); 
        
        //check
        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn[0], address(vBNB));

        //borrow usdc 100
        uint borrowAmount = 100 * 1e18;
        vUSDC.borrow(borrowAmount);

        usdc.approve(address(vUSDC), borrowAmount);
        //repay borrowAmount
        vUSDC.repayBorrow(borrowAmount);
        assertEq(usdc.balanceOf(address(this)),0);
    }
    function test_repayBorrowBehalf() public {
        vm.startPrank(user);
        vBNB.mint{value : 1e18}();
        
        //enter vBNB market
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vBNB);
        comptroller.enterMarkets(vTokens); 
        
        //check
        address[] memory assetsIn = comptroller.getAssetsIn(address(user));
        assertEq(assetsIn[0], address(vBNB));

        //borrow usdc 100
        uint borrowAmount = 100 * 1e18;
        vUSDC.borrow(borrowAmount);
        vm.stopPrank();
        
        vm.roll(block.number + 3);
        
        // totalBorrows = borrowAmount + interest
        uint amount=vUSDC.borrowBalanceCurrent(user);

        deal(address(usdc),address(this),amount);
        usdc.approve(address(vUSDC), amount);
        
        //repay user's totalBorrows
        vUSDC.repayBorrowBehalf(user, amount);

        assertEq(vUSDC.borrowBalanceCurrent(user),0);
    }


    function getExchangeRate() internal returns (uint) {
        // exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply.
        uint totalCash = vBNB.getCash();
        assertEq(totalCash, address(vBNB).balance);

        uint totalBorrows = vBNB.totalBorrowsCurrent();

        uint totalReserves = vBNB.totalReserves();

        uint totalSupply = vBNB.totalSupply();

        uint exchangeRate = 1e18 * (totalCash + totalBorrows  - totalReserves) / totalSupply;
        return exchangeRate;
    }

    function test_redeem() public {
        uint initialBalance = address(this).balance;
        vBNB.mint{value : 1e18}();
        
        //test equal exchange rate  
        uint test = getExchangeRate();
        uint exchangeRate = vBNB.exchangeRateCurrent();
        assertEq(test,exchangeRate);

        uint vBNBamount = vBNB.balanceOf(address(this));
        uint mintTokens = 1e18 * 1e18 / exchangeRate;
        assertEq(vBNBamount,mintTokens);

        vm.roll(block.number + 100);
        
        vBNB.redeem(vBNB.balanceOf(address(this)));
        assertEq(vBNB.balanceOf(address(this)),0);

        //should have more bnb with 100 block of interests.
        assert(address(this).balance > initialBalance);
    }

    function test_redeemUnderlying() public{
        vBNB.mint{value : 1e18}();
        uint bf = vBNB.balanceOf(address(this));
        vm.roll(block.number + 1);
        
        uint amount = address(this).balance;
        vBNB.redeemUnderlying(1e18);
        assertEq(address(this).balance - 1e18, amount);

        //calculation underlying amount
        uint exchangeRate = vBNB.exchangeRateCurrent();
        uint calc = 1e18 * 1e18/exchangeRate;
        uint af = vBNB.balanceOf(address(this));
        assertEq(af, bf-calc);
    }

    function test_transfer() public {
        vBNB.mint{value: 1e18}();
        uint amonut = vBNB.balanceOf(address(this));

        vBNB.transfer(user,vBNB.balanceOf(address(this)));

        assertEq(amonut,vBNB.balanceOf(user));
    }

    function test_liquidate() public {
        vm.deal(user, 1e18);
        vm.startPrank(user);
        vBNB.mint{value : 1e18}();

        //enter market
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vBNB);
        comptroller.enterMarkets(vTokens);

        //borrow 100 usdc
        uint borrowAmount = 100 * 1e18;
        vUSDC.borrow(borrowAmount);
        
        vm.stopPrank();
        
        vm.roll(block.number + 5);

        uint setAmount = 100 * 1e18;
        deal(address(usdc),address(this),setAmount);
        usdc.approve(address(liquidator),setAmount);
        
         //Set bnb price 575637491570000000000 -> 637491570000000000
        vm.mockCall(
            address(oracle),
            abi.encodeWithSelector(oracle.getUnderlyingPrice.selector,address(vBNB)),
            abi.encode(637491570000000000)
        );
        //check MAX repayAmount
        uint factor = comptroller.closeFactorMantissa();
        uint borrowed = vUSDC.borrowBalanceCurrent(user);
        uint amount = (borrowed * factor) / 1e18;
        
        vm.expectRevert();
         //repayAmount =< maxRepay(closeFactor * totalBorrow)
        liquidator.liquidateBorrow(address(vUSDC),user, amount+1, vBNB);
        
        //borrower collateral totalToken(4083941419) >= seizeToken Amount
        liquidator.liquidateBorrow(address(vUSDC),user, 1, vBNB);
    }
    function test_enterMarket() public {
        address[] memory markets = new address[](1);
        markets[0] = address(vBNB);
        comptroller.enterMarkets(markets);

        // Checks
        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn[0], address(vBNB));
    }
    function test_exitMarket() public {
        address[] memory markets = new address[](1);
        markets[0] = address(vBNB);
        comptroller.enterMarkets(markets);

        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn.length, 1);

        comptroller.exitMarket(address(vBNB));
        assetsIn = comptroller.getAssetsIn(address(this));
        //check delete asset
        assertEq(assetsIn.length, 0);
    }


    receive() payable external{}

}


