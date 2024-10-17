// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";

/// @title Errors
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Contract implementing EVault's custom errors
contract Errors {
    error E_Initialized();
    error E_ProxyMetadata();
    error E_SelfTransfer();
    error E_InsufficientAllowance();
    error E_InsufficientCash();
    error E_InsufficientAssets();
    error E_InsufficientBalance();
    error E_InsufficientDebt();
    error E_FlashLoanNotRepaid();
    error E_Reentrancy();
    error E_OperationDisabled();
    error E_OutstandingDebt();
    error E_AmountTooLargeToEncode();
    error E_DebtAmountTooLargeToEncode();
    error E_RepayTooMuch();
    error E_TransientState();
    error E_SelfLiquidation();
    error E_ControllerDisabled();
    error E_CollateralDisabled();
    error E_ViolatorLiquidityDeferred();
    error E_LiquidationCoolOff();
    error E_ExcessiveRepayAmount();
    error E_MinYield();
    error E_BadAddress();
    error E_ZeroAssets();
    error E_ZeroShares();
    error E_Unauthorized();
    error E_CheckUnauthorized();
    error E_NotSupported();
    error E_EmptyError();
    error E_BadBorrowCap();
    error E_BadSupplyCap();
    error E_BadCollateral();
    error E_AccountLiquidity();
    error E_NoLiability();
    error E_NotController();
    error E_BadFee();
    error E_SupplyCapExceeded();
    error E_BorrowCapExceeded();
    error E_InvalidLTVAsset();
    error E_NoPriceOracle();
    error E_ConfigAmountTooLargeToEncode();
    error E_BadAssetReceiver();
    error E_BadSharesOwner();
    error E_BadSharesReceiver();
    error E_BadMaxLiquidationDiscount();
    error E_LTVBorrow();
    error E_LTVLiquidation();
    error E_NotHookTarget();


    /// @notice Error for when caller is not authorized to perform an operation.
    error EVC_NotAuthorized();
    /// @notice Error for when no account has been authenticated to act on behalf of.
    error EVC_OnBehalfOfAccountNotAuthenticated();
    /// @notice Error for when an operator's to be set is no different from the current one.
    error EVC_InvalidOperatorStatus();
    /// @notice Error for when a nonce is invalid or already used.
    error EVC_InvalidNonce();
    /// @notice Error for when an address parameter passed is invalid.
    error EVC_InvalidAddress();
    /// @notice Error for when a timestamp parameter passed is expired.
    error EVC_InvalidTimestamp();
    /// @notice Error for when a value parameter passed is invalid or exceeds current balance.
    error EVC_InvalidValue();
    /// @notice Error for when data parameter passed is empty.
    error EVC_InvalidData();
    /// @notice Error for when an action is prohibited due to the lockdown mode.
    error EVC_LockdownMode();
    /// @notice Error for when permit execution is prohibited due to the permit disabled mode.
    error EVC_PermitDisabledMode();
    /// @notice Error for when checks are in progress and reentrancy is not allowed.
    error EVC_ChecksReentrancy();
    /// @notice Error for when control collateral is in progress and reentrancy is not allowed.
    error EVC_ControlCollateralReentrancy();
    /// @notice Error for when there is a different number of controllers enabled than expected.
    error EVC_ControllerViolation();
    /// @notice Error for when a simulation batch is nested within another simulation batch.
    error EVC_SimulationBatchNested();
    /// @notice Auxiliary error to pass simulation batch results.
    error EVC_RevertedBatchResult(
        IEVC.BatchItemResult[] batchItemsResult,
        IEVC.StatusCheckResult[] accountsStatusResult,
        IEVC.StatusCheckResult[] vaultsStatusResult
    );
    /// @notice Panic error for when simulation does not behave as expected. Should never be observed.
    error EVC_BatchPanic();
    /// @notice Error for when an empty or undefined error is thrown.
    error EVC_EmptyError();
}
