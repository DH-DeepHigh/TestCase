// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "./ComptrollerInterface.sol";
import "./IBEP20Interface.sol";
interface VTokenInterface{
    function accrualBlockNumber() external view returns (uint);
    function admin() external  returns (address payable);
    
    function pendingAdmin() external  returns (address payable);

    function comptroller() external  returns (address);
    
    function reserveFactorMantissa() external returns (uint);
    
    function interestRateModel() external  returns (address);
    
    function balanceOf(address owner) external view returns (uint256);

    function mint() external payable;
    
    function mint(uint256 mintAmount) external  returns (uint256);
    
    function mintBehalf(address minter) external  payable;
    
    function mintBehalf(address minter, uint256 mintAllowed) external  returns (uint256);

    function redeem(uint256 redeemTokens) external  returns (uint256);

    function redeemBehalf(address redeemer, uint256 redeemTokens) external  returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external  returns (uint256);

    function redeemUnderlyingBehalf(address redeemer, uint256 redeemAmount) external  returns (uint256);

    function borrow(uint256 borrowAmount) external  returns (uint256);

    function borrowBehalf(address borrwwer, uint256 borrowAmount) external  returns (uint256);

    function repayBorrow(uint256 repayAmount) external  returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external  returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral
    ) external  returns (uint256);

    function healBorrow(address payer, address borrower, uint256 repayAmount) external ;

    function forceLiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address vTokenCollateral,
        bool skipCloseFactorCheck
    ) external ;

    function seize(address liquidator, address borrower, uint256 seizeTokens) external ;

    function transfer(address dst, uint256 amount) external  returns (bool);

    function transferFrom(address src, address dst, uint256 amount) external  returns (bool);

    function accrueInterest() external  returns (uint256);

    function sweepToken(address token) external;

    function borrowBalanceCurrent(address account) external  returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);
    
    function totalReserves() external  returns (uint256);

    function totalSupply() external  returns (uint256);

    function badDebt() external  returns (uint256);

    function getCash() external view returns (uint256);
    //admin function
    function _setPendingAdmin(address payable newPendingAdmin)  external returns (uint);
    
    function _acceptAdmin()  external returns (uint);
    
    function _setComptroller(ComptrollerInterface newComptroller)  external returns (uint);
    
    function _setReserveFactor(uint newReserveFactorMantissa)  external returns (uint);
    
    function _reduceReserves(uint reduceAmount)  external returns (uint);

    function reduceReserves(uint reduceAmount)  external;
    
    function _setInterestRateModel(InterestRateModel newInterestRateModel)  external returns (uint);

    function implementation() external returns(address);
    
    //only cErc20delegate
    function _resignImplementation() external;
    function _becomeImplementation(bytes memory data)  external;
    
    //only cErc20delegator
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData)  external;
}
abstract contract InterestRateModel {
    bool public constant isInterestRateModel = true;

    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual external view returns (uint);
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual external view returns (uint);

}interface liquidateInterface{
        function liquidateBorrow(
        address vToken,
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral
    ) external payable;
}