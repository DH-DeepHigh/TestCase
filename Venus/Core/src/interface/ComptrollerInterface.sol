// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "../interface/VTokenInterface.sol";

interface ComptrollerInterface {
    function _setProtocolPaused(bool state) external returns (bool);
    function borrowCaps(address vToken) external view returns (uint);

    function checkMembership(address account, address vToken) external view returns (bool);
    /*** Policy Hooks ***/
    function mintAllowed(address vToken, address minter, uint mintAmount) external returns (uint);

    function redeemAllowed(address vToken, address redeemer, uint redeemTokens) external returns (uint);

    function borrowAllowed(address vToken, address borrower, uint borrowAmount) external returns (uint);

    function repayBorrowAllowed(
        address vToken,
        address payer,
        address borrower,
        uint repayAmount
    ) external returns (uint);

    function liquidateBorrowAllowed(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external returns (uint);
    
    
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata vTokens) external returns (uint256[] memory);

    function exitMarket(address vToken) external returns (uint256);

    /*** Policy Hooks ***/

    function preMintHook(address vToken, address minter, uint256 mintAmount) external;

    function preRedeemHook(address vToken, address redeemer, uint256 redeemTokens) external;

    function preBorrowHook(address vToken, address borrower, uint256 borrowAmount) external;

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
        address vTokenBorrowed,
        address liquidator,
        address borrower
    ) external;

    function borrowVerify(address vToken, address borrower, uint borrowAmount) external;

    function mintVerify(address vToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemVerify(address vToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function repayBorrowVerify(
        address vToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex
    ) external;

    function liquidateBorrowVerify(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens
    ) external;

    function seizeVerify(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external;

    function transferVerify(address vToken, address src, address dst, uint transferTokens) external;

    function preTransferHook(address vToken, address src, address dst, uint256 transferTokens) external;

    function isComptroller() external view returns (bool);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address vTokenBorrowed,
        address vTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);



    function closeFactorMantissa() external view returns (uint256);


    function minLiquidatableCollateral() external view returns (uint256);
    

    function updateDelegate(address delegate, bool approved) external;
    function getHypotheticalAccountLiquidity(
        address account,
        address vTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) external view returns (uint256, uint256, uint256);
    
    function getXVSAddress() external view returns (address);

    function markets(address) external view returns (bool, uint);

    function oracle() external view returns (address);

    function getAccountLiquidity(address) external view returns (uint, uint, uint);

    function getAssetsIn(address) external view returns (address[] memory);

    function claimVenus(address) external;

    function venusAccrued(address) external view returns (uint);

    function venusSupplySpeeds(address) external view returns (uint);

    function venusBorrowSpeeds(address) external view returns (uint);

    function getAllMarkets() external view returns (address[] memory);

    function venusSupplierIndex(address, address) external view returns (uint);

    function venusInitialIndex() external view returns (uint224);

    function venusBorrowerIndex(address, address) external view returns (uint);

    function venusBorrowState(address) external view returns (uint224, uint32);

    function venusSupplyState(address) external view returns (uint224, uint32);

    function approvedDelegates(address borrower, address delegate) external view returns (bool);

    function vaiController() external view returns (address);

    function liquidationIncentiveMantissa() external view returns (uint);

    function protocolPaused() external view returns (bool);

    function mintedVAIs(address user) external view returns (uint);

    function vaiMintRate() external view returns (uint);
}

interface IVAIVault {
    function updatePendingRewards() external;
}

interface IComptroller {
    function liquidationIncentiveMantissa() external view returns (uint);

    /*** Treasury Data ***/
    function treasuryAddress() external view returns (address);

    function treasuryPercent() external view returns (uint);
}
