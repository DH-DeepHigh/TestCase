// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./interface/ComptrollerInterface.sol";
import "./interface/VTokenInterface.sol";
import "forge-std/Test.sol";
import "./VenusUtils.sol";

contract testComptroller is ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;
    function _setProtocolPaused(bool state) override external returns (bool){}
    function borrowCaps(address vToken) override external view returns (uint){}
    function checkMembership(address account, address vToken) override external view returns (bool){}
    function mintAllowed(address vToken, address minter, uint mintAmount) override external returns (uint){}

    function redeemAllowed(address vToken, address redeemer, uint redeemTokens) override external returns (uint){}

    function borrowAllowed(address vToken, address borrower, uint borrowAmount) override external returns (uint){}

    function repayBorrowAllowed(
        address vToken,
        address payer,
        address borrower,
        uint repayAmount
    ) override external returns (uint){}

    function liquidateBorrowAllowed(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) override external returns (uint){}
    
    
    /*** Assets You Are In ***/

     function enterMarkets(address[] calldata vTokens) override external returns (uint256[] memory){}

     function exitMarket(address vToken) override external returns (uint256){}

     /*** Policy Hooks ***/

     function preMintHook(address vToken, address minter, uint256 mintAmount) override external{}

     function preRedeemHook(address vToken, address redeemer, uint256 redeemTokens) override external{}

     function preBorrowHook(address vToken, address borrower, uint256 borrowAmount) override external{}

     function preRepayHook(address vToken, address borrower) override external{}

     function preLiquidateHook(
         address vTokenBorrowed,
         address vTokenCollateral,
         address borrower,
         uint256 repayAmount,
         bool skipLiquidityCheck
     ) override external{}

     function preSeizeHook(
         address vTokenCollateral,
         address vTokenBorrowed,
         address liquidator,
         address borrower
     ) override external{}

     function borrowVerify(address vToken, address borrower, uint borrowAmount) override external{}

     function mintVerify(address vToken, address minter, uint mintAmount, uint mintTokens) override external{}

     function redeemVerify(address vToken, address redeemer, uint redeemAmount, uint redeemTokens) override external{}

     function repayBorrowVerify(
         address vToken,
         address payer,
         address borrower,
         uint repayAmount,
         uint borrowerIndex
     ) override external{}

     function liquidateBorrowVerify(
         address vTokenBorrowed,
         address vTokenCollateral,
         address liquidator,
         address borrower,
         uint repayAmount,
         uint seizeTokens
     ) override external{}

     function seizeVerify(
         address vTokenCollateral,
         address vTokenBorrowed,
         address liquidator,
         address borrower,
         uint seizeTokens
     ) override external{}

     function transferVerify(address vToken, address src, address dst, uint transferTokens) override external{}

     function preTransferHook(address vToken, address src, address dst, uint256 transferTokens) override external{}

     /*** Liquidity/Liquidation Calculations ***/

     function liquidateCalculateSeizeTokens(
         address vTokenBorrowed,
         address vTokenCollateral,
         uint256 repayAmount
     ) override external view returns (uint256, uint256){}



     function closeFactorMantissa() override external view returns (uint256){}


     function minLiquidatableCollateral() override external view returns (uint256){}
    

     function updateDelegate(address delegate, bool approved) override external{}
     function getHypotheticalAccountLiquidity(
         address account,
         address vTokenModify,
         uint256 redeemTokens,
         uint256 borrowAmount
     ) override external view returns (uint256, uint256, uint256){}
    
     function getXVSAddress() override external view returns (address){}

     function markets(address) override external view returns (bool, uint){}

     function oracle() override external view returns (address){}

     function getAccountLiquidity(address) override external view returns (uint, uint, uint){}

     function getAssetsIn(address) override external view returns (address[] memory){}

     function claimVenus(address) override external{}

     function venusAccrued(address) override external view returns (uint){}

     function venusSupplySpeeds(address) override external view returns (uint){}

     function venusBorrowSpeeds(address) override external view returns (uint){}

     function getAllMarkets() override external view returns (address[] memory){}

     function venusSupplierIndex(address, address) override external view returns (uint){}

     function venusInitialIndex() override external view returns (uint224){}

     function venusBorrowerIndex(address, address) override external view returns (uint){}

     function venusBorrowState(address) override external view returns (uint224, uint32){}

     function venusSupplyState(address) override external view returns (uint224, uint32){}

     function approvedDelegates(address borrower, address delegate) override external view returns (bool){}

     function vaiController() override external view returns (address){}

     function liquidationIncentiveMantissa() override external view returns (uint){}

     function protocolPaused() override external view returns (bool){}

     function mintedVAIs(address user) override external view returns (uint){}

     function vaiMintRate() override external view returns (uint){}
}

abstract contract InterestRateModel {
    bool public constant isInterestRateModel = true;

    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual external view returns (uint);
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual external view returns (uint);
}

contract testInterestRateModel is InterestRateModel{
    function getBorrowRate(uint cash, uint borrows, uint reserves) override external view returns (uint){}
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) override external view returns (uint){}

}

contract testCToken is VTokenInterface{
    bool public constant isCToken = true;
    function accrualBlockNumber() override external view returns (uint){}
    function balanceOf(address owner) override external view returns (uint256){}

    function mint() override external payable{}
    
    function mint(uint256 mintAmount) override external  returns (uint256){}
    
    function mintBehalf(address minter) override external  payable{}
    
    function mintBehalf(address minter, uint256 mintAllowed) override external  returns (uint256){}

    function redeem(uint256 redeemTokens) override external  returns (uint256){}

    function redeemBehalf(address redeemer, uint256 redeemTokens) override external  returns (uint256){}

    function redeemUnderlying(uint256 redeemAmount) override external  returns (uint256){}

    function redeemUnderlyingBehalf(address redeemer, uint256 redeemAmount) override external  returns (uint256){}

    function borrow(uint256 borrowAmount) override external  returns (uint256){}

    function borrowBehalf(address borrwwer, uint256 borrowAmount) override external  returns (uint256){}

    function repayBorrow(uint256 repayAmount) override external  returns (uint256){}

    function repayBorrowBehalf(address borrower, uint256 repayAmount) override external  returns (uint256){}

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral
    ) override external  returns (uint256){}

    function healBorrow(address payer, address borrower, uint256 repayAmount) override external {}

    function forceLiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address vTokenCollateral,
        bool skipCloseFactorCheck
    ) override external {}

    function seize(address liquidator, address borrower, uint256 seizeTokens) override external {}

    function transfer(address dst, uint256 amount) override external  returns (bool){}

    function transferFrom(address src, address dst, uint256 amount) override external  returns (bool){}

    function accrueInterest() override external  returns (uint256){}

    function sweepToken(address token) override external{}

    function borrowBalanceCurrent(address account) override external  returns (uint256){}

    function exchangeRateCurrent() override external returns (uint256){}

    function totalBorrowsCurrent() override external returns (uint256){}
    
    function totalReserves() override external  returns (uint256){}

    function totalSupply() override external  returns (uint256){}

    function badDebt() override external  returns (uint256){}

    function getCash() override external view returns (uint256){}
   
}

contract tools is Test, VenusUtils{
    using stdStorage for StdStorage;
    testCToken deploy = new testCToken();
    VTokenInterface Not_registered_vToken= VTokenInterface(deploy);
    function Pause() public {
        vm.startPrank(admin);
        comptroller._setProtocolPaused(true);
        vm.stopPrank();
    }
    function unPause() public {
        vm.startPrank(admin);
        comptroller._setProtocolPaused(false);
        vm.stopPrank();
    }
    function pass_accrueInterest() public{
        vm.mockCall(
            address(Not_registered_vToken),
            abi.encodeWithSelector(Not_registered_vToken.accrueInterest.selector),
            abi.encode(0)
        );
    }
}