// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

/**
 * @title ComptrollerInterface
 * @author Venus
 * @notice Interface implemented by the `Comptroller` contract.
 */

 interface IComptroller {

    enum Action {
        MINT,
        REDEEM,
        BORROW,
        REPAY,
        SEIZE,
        LIQUIDATE,
        TRANSFER,
        ENTER_MARKET,
        EXIT_MARKET
    }

    function initialize(uint256 loopLimit, address accessControlManager) external;

    function enterMarkets(address[] memory vTokens) external returns (uint256[] memory);

    function unlistMarket(address market) external returns (uint256);

    function updateDelegate(address delegate, bool approved) external;

    function exitMarket(address vTokenAddress) external returns (uint256);

    function preMintHook(address vToken, address minter, uint256 mintAmount) external;

    function mintVerify(address vToken, address minter, uint256 actualMintAmount, uint256 mintTokens) external;

    function preRedeemHook(address vToken, address redeemer, uint256 redeemTokens) external;

    function redeemVerify(address vToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens) external;

    function repayBorrowVerify(
        address vToken,
        address payer,
        address borrower,
        uint256 actualRepayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowVerify(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint256 actualRepayAmount,
        uint256 seizeTokens
    ) external;

    function seizeVerify(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferVerify(address vToken, address src, address dst, uint256 transferTokens) external;

    function preBorrowHook(address vToken, address borrower, uint256 borrowAmount) external;

    function borrowVerify(address vToken, address borrower, uint256 borrowAmount) external;

    function preRepayHook(address vToken, address borrower) external;

    function preLiquidateHook(
        address vTokenBorrowed,
        address vTokenCollateral,
        address borrower,
        uint256 repayAmount,
        bool skipLiquidityCheck
    ) external;

    function preSeizeHook(
        address vTokenCollateral,
        address seizerContract,
        address liquidator,
        address borrower
    ) external;

    function preTransferHook(
        address vToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function setCloseFactor(uint256 newCloseFactorMantissa) external;

    function setCollateralFactor(
        address vToken,
        uint256 newCollateralFactorMantissa,
        uint256 newLiquidationThresholdMantissa
    ) external;

    function setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external;

    function supportMarket(address vToken) external;

    function setMarketBorrowCaps(address[] calldata vTokens, uint256[] calldata newBorrowCaps) external;

    function setMarketSupplyCaps(address[] calldata vTokens, uint256[] calldata newSupplyCaps) external;

    function setActionsPaused(address[] calldata marketsList, Action[] calldata actionsList, bool paused) external;

    function setMinLiquidatableCollateral(uint256 newMinLiquidatableCollateral) external;
}
