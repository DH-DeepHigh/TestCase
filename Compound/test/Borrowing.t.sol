// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/TestUtils.sol";
import "../src/interfaces/Exponential.sol";
import "../src/TestFile.sol";
import "../src/interfaces/Error.sol";

contract BorrowingTest is Test, TestUtils, Exponential, tools, TokenErrorReporter{
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

    function test_borrow_pause() public {
        set_pause();
        vm.expectRevert("borrow is paused");
        cDai.borrow(borrowAmount);

        set_unpause();
        cDai.borrow(borrowAmount);
        assertEq(dai.balanceOf(borrower), borrowAmount);
    }

    function test_borrow_marketList() public{
        /*
        Market list check
        mint call Sequence mint => mintInternal => mintFresh => mintAllowed
        */
        uint Errorcode =comptroller.borrowAllowed(address(Not_registered_CToken),borrower,borrowAmount);
        
        // Errorcode = MARKET_NOT_LISTED
        assertEq(Errorcode,9);

        Errorcode =comptroller.mintAllowed(address(cDai),borrower,borrowAmount);
        
        // Errorcode =NO.ERROR
        assertEq(Errorcode, 0);
    }
    function test_borrow_underlyingPrice() public{
        //set underlying price zero  & Previous underlying price
        uint amount=set_borrow_price_zero();

        bytes memory errorcode = abi.encodeWithSignature("BorrowComptrollerRejection(uint256)", 13);
        vm.expectRevert(errorcode);
        
        cDai.borrow(borrowAmount);

        set_borrow_price_rollback(amount);
        cDai.borrow(borrowAmount);
        assertEq(dai.balanceOf(borrower),borrowAmount);
    }
    
}