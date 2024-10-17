// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library AddressList {
    // Core Aave Contracts
    address public constant ACL_MANAGER = 0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0;
    address public constant POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant POOL_CONFIGURATOR = 0x64b761D848206f447Fe2dd461b0c635Ec39EbB27;
    address public constant INCENTIVES = 0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb;
    address public constant POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address public constant POOL_ADDRESSES_PROVIDER_REGISTRY = 0xbaA999AC55EAce41CcAE355c77809e68Bb345170;

    // Data Providers
    address public constant POOL_DATA_PROVIDER = 0x41393e5e337606dc3821075Af65AeE84D7688CBD;
    address public constant UI_INCENTIVE_DATA_PROVIDER_V3 = 0x5a40cDe2b76Da2beD545efB3ae15708eE56aAF9c;
    address public constant UI_POOL_DATA_PROVIDER_V3 = 0x194324C9Af7f56E22F1614dD82E18621cb9238E7;

    // Gateway Contracts
    address public constant WRAPPED_TOKEN_GATEWAY = 0xA434D495249abE33E031Fe71a969B81f3c07950D;

    // Utility Providers
    address public constant WALLET_BALANCE_PROVIDER = 0xC7be5307ba715ce89b152f3Df0658295b3dbA8E2;
    address public constant AAVE_ORACLE = 0x54586bE62E3c3580375aE3723C145253060Ca0C2;

    // Treasury
    address public constant TREASURY = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
    address public constant TREASURY_CONTROLLER = 0x3d569673dAa0575c936c7c67c4E6AedA69CC630C;

    // Adapter Contracts
    address public constant LIQUIDITY_SWITCH_ADAPTER = 0xADC0A53095A0af87F3aa29FE0715B5c28016364e;
    address public constant REPAY_WITH_COLLATERAL_ADAPTER = 0x35bb522b102326ea3F1141661dF4626C87000e3E;
    address public constant DEBT_SWITCH_ADAPTER = 0xd7852E139a7097E119623de0751AE53a61efb442;
    address public constant WITHDRAW_SWITCH_ADAPTER = 0x78F8Bd884C3D738B74B420540659c82f392820e0;

    // Migration Contract
    address public constant MIGRATION_CONTRACT = 0xB748952c7BC638F31775245964707Bcc5DDFabFC;

    // Token
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

}
