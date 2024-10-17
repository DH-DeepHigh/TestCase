// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "../src/VenusUtils.sol";

/// @notice Example contract that calculates the account liquidity.
contract vBEP20_Test is Test, VenusUtils {
    address user =address(0x1234);
    function setUp() public {
        // Fork mainnet at block 43_056_300.
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        uint amount = 10000 * 1e18;
        deal(address(eth),address(this),amount);
        deal(address(eth),user, 1e18);
        eth.approve(address(vETH),amount);
    }
    function test_mint() public {
        vETH.mint(1e18);
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vETH);
        comptroller.enterMarkets(vTokens);

        (, uint collateralFactorMantissa) = comptroller.markets(address(vETH));

        (, uint liquidity,) = comptroller.getAccountLiquidity(address(this));
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vETH));

        uint expectedLiquidity = (price * collateralFactorMantissa / 1e18) / 1e18;
        assertEq(liquidity, expectedLiquidity);
    }
    function test_mintBehalf() public {
        vETH.mintBehalf(address(this),1e18);
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vETH);
        comptroller.enterMarkets(vTokens);

        (, uint collateralFactorMantissa) = comptroller.markets(address(vETH));

        (, uint liquidity,) = comptroller.getAccountLiquidity(address(this));
        liquidity = liquidity / 1e18;

        uint price = oracle.getUnderlyingPrice(address(vETH));

        uint expectedLiquidity = (price * collateralFactorMantissa / 1e18) / 1e18;
        assertEq(liquidity, expectedLiquidity);
    }

    function test_borrow() public {
        vETH.mint(1e18);
        
        //enter vETH market
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vETH);
        comptroller.enterMarkets(vTokens); 
        
        //check
        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn[0], address(vETH));

        //borrow usdc 100
        uint borrowAmount = 100 * 1e18;
        vUSDC.borrow(borrowAmount);

        assertEq(usdc.balanceOf(address(this)), borrowAmount);
    }
    function test_borrowBehalf() public {
        vm.startPrank(user);
        eth.approve(address(vETH),1e18);
        vETH.mint(1e18);
        
        //enter vETH market
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vETH);
        comptroller.enterMarkets(vTokens); 
        
        //check
        address[] memory assetsIn = comptroller.getAssetsIn(user);
        assertEq(assetsIn[0], address(vETH));
        
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
        vETH.mint(1e18);
        //enter vETH market
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vETH);
        comptroller.enterMarkets(vTokens); 
        
        //check
        address[] memory assetsIn = comptroller.getAssetsIn(address(this));
        assertEq(assetsIn[0], address(vETH));

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
        eth.approve(address(vETH),1e18);
        vETH.mint(1e18);
        
        //enter vETH market
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vETH);
        comptroller.enterMarkets(vTokens); 
        
        //check
        address[] memory assetsIn = comptroller.getAssetsIn(address(user));
        assertEq(assetsIn[0], address(vETH));

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
        uint totalCash = vETH.getCash();
        assertEq(totalCash, eth.balanceOf(address(vETH)));

        uint totalBorrows = vETH.totalBorrowsCurrent();

        uint totalReserves = vETH.totalReserves();

        uint totalSupply = vETH.totalSupply();

        uint exchangeRate = 1e18 * (totalCash + totalBorrows  - totalReserves) / totalSupply;
        return exchangeRate;
    }

    function test_redeem() public {
        uint initialBalance = eth.balanceOf(address(this));
        vETH.mint(1e18);
        
        //test equal exchange rate  
        uint test = getExchangeRate();
       uint exchangeRate = vETH.exchangeRateCurrent();
        assertEq(test,exchangeRate);

        uint vETHamount = vETH.balanceOf(address(this));
        uint mintTokens = 1e18 * 1e18 / exchangeRate;
        assertEq(vETHamount,mintTokens);

        vm.roll(block.number + 100);
        
        vETH.redeem(vETH.balanceOf(address(this)));
        assertEq(vETH.balanceOf(address(this)),0);

        //should have more bnb with 100 block of interests.
        assert(eth.balanceOf(address(this)) > initialBalance);
    }

    function test_redeemUnderlying() public{
        vETH.mint(1e18);
        uint bf = vETH.balanceOf(address(this));
        vm.roll(block.number + 1);
        
        uint amount = eth.balanceOf(address(this));
        vETH.redeemUnderlying(1e18);
        assertEq(eth.balanceOf(address(this)) - 1e18, amount);

        //calculation underlying amount
        uint exchangeRate = vETH.exchangeRateCurrent();
        uint calc = 1e18 * 1e18/exchangeRate;
        uint af = vETH.balanceOf(address(this));
        assertEq(af, bf-calc);
    }

    function test_transfer() public {
        vETH.mint(1e18);
        uint amonut = vETH.balanceOf(address(this));

        vETH.transfer(user,vETH.balanceOf(address(this)));

        assertEq(amonut,vETH.balanceOf(user));
    }

    function test_liquidate() public {
        vm.startPrank(user);
        eth.approve(address(vETH),1e18);
        vETH.mint(1e18);

        //enter market
        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vETH);
        comptroller.enterMarkets(vTokens);

        //borrow 100 usdc
        uint borrowAmount = 100 * 1e18;
        vUSDC.borrow(borrowAmount);
        
        vm.stopPrank();
        
        vm.roll(block.number + 5);

        uint setAmount = 100 * 1e18;
        deal(address(usdc),address(this),setAmount);
        usdc.approve(address(liquidator),setAmount);
        console.log(oracle.getUnderlyingPrice(address(vETH)));
        
         //Set bnb price 2470800000000000000000 -> 800000000000000000
        vm.mockCall(
            address(oracle),
            abi.encodeWithSelector(oracle.getUnderlyingPrice.selector,address(vETH)),
            abi.encode(800000000000000000)
        );
        //check MAX repayAmount
        uint factor = comptroller.closeFactorMantissa();
        uint borrowed = vUSDC.borrowBalanceCurrent(user);
        uint amount = (borrowed * factor) / 1e18;
        
        vm.expectRevert();
         //repayAmount =< maxRepay(closeFactor * totalBorrow)
        liquidator.liquidateBorrow(address(vUSDC),user, amount+1, vETH);
        
         //borrower collateral totalToken(4818919171) >= seizeToken Amount
         liquidator.liquidateBorrow(address(vUSDC),user, 7e17, vETH);
    }


    receive() payable external{}

}


