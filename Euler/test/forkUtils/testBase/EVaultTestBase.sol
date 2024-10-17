// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import {Test, console2, stdError} from "forge-std/Test.sol";
import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";

import {GenericFactory} from "../../../src/GenericFactory/GenericFactory.sol";

import {EVault} from "../../../src/EVault/EVault.sol";
import {ProtocolConfig} from "../../../src/ProtocolConfig/ProtocolConfig.sol";

import {Dispatch} from "../../../src/EVault/Dispatch.sol";

import {Initialize} from "../../../src/EVault/modules/Initialize.sol";
import {Token} from "../../../src/EVault/modules/Token.sol";
import {Vault} from "../../../src/EVault/modules/Vault.sol";
import {Borrowing} from "../../../src/EVault/modules/Borrowing.sol";
import {Liquidation} from "../../../src/EVault/modules/Liquidation.sol";
import {BalanceForwarder} from "../../../src/EVault/modules/BalanceForwarder.sol";
import {Governance} from "../../../src/EVault/modules/Governance.sol";
import {RiskManager} from "../../../src/EVault/modules/RiskManager.sol";

import {IEVault, IERC20} from "../../../src/EVault/IEVault.sol";
import {TypesLib} from "../../../src/EVault/shared/types/Types.sol";
import {Base} from "../../../src/EVault/shared/Base.sol";

import {EthereumVaultConnector} from "ethereum-vault-connector/EthereumVaultConnector.sol";

import {TestERC20} from "../mocks/TestERC20.sol";
import {MockBalanceTracker} from "../mocks/MockBalanceTracker.sol";
import {IPriceOracle} from "../../../src/interfaces/IPriceOracle.sol";
import {IRMTestDefault} from "../mocks/IRMTestDefault.sol";
import {IHookTarget} from "../../../src/interfaces/IHookTarget.sol";
import {SequenceRegistry} from "../../../src/SequenceRegistry/SequenceRegistry.sol";

import {AssertionsCustomTypes} from "../helpers/AssertionsCustomTypes.sol";
import "./InvariantOverrides.sol";

import "../../../src/EVault/shared/Constants.sol";

interface CheatCodes {
    function createFork(string calldata, uint256) external returns (uint256);
    function createSelectFork(string calldata, uint256) external returns (uint256);
    function startPrank(address) external;
    function stopPrank() external;
}

contract addressUtils {
    CheatCodes cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    EthereumVaultConnector evc = EthereumVaultConnector(payable(0x0C9a3dd6b8F28529d72d7f9cE918D493519EE383));
    address admin = 0xEe009FAF00CF54C1B4387829aF7A8Dc5f0c8C8C5;

    IERC20 DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    address eDAI_creator = 0x9A363c4e9B4AB466637FA6A11E5606fA4AAc1b18;
    IEVault eDAI = IEVault(0x17ec0701F4683239a4A388D6B3E322D1F874ABdC);
    
    address eWETH_creator = 0xEe009FAF00CF54C1B4387829aF7A8Dc5f0c8C8C5;
    IEVault eWETH = IEVault(0xb3b36220fA7d12f7055dab5c9FD18E860e9a6bF8);

    ProtocolConfig protocolConfig = ProtocolConfig(0x4cD6BF1D183264c02Be7748Cb5cd3A47d013351b);
    address protocolFeeReceiver = 0xFcd3Db06EA814eB21C84304fC7F90798C00D1e32;
    address feeReceiver = 0xd9Db0bf1AA15B255405A259D2a8d127F1bE6e2a2;
    address balanceTracker = 0x0D52d06ceB8Dcdeeb40Cfd9f17489B350dD7F8a3;
    GenericFactory factory = GenericFactory(0x29a56a1b8214D9Cf7c5561811750D5cBDb45CC8e);
    address permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    IPriceOracle oracle = IPriceOracle(0x7d67eFCFF0757992141511D6dfB60AEf89629974);

    // address initializeModule;
    // address tokenModule;
    // address vaultModule;
    // address borrowingModule;
    // address liquidationModule;
    // address riskManagerModule;
    // address balanceForwarderModule;
    // address governanceModule;

    /// @dev We are forking mainnet at this block number for all test cases.
    uint256 public constant BLOCK_NUMBER = 20_941_968;
}

contract EVaultTestBase is AssertionsCustomTypes, Test, DeployPermit2, addressUtils {
    // Base.Integrations integrations;
    // Dispatch.DeployedModules modules;
    
    // TestERC20 WETH;
    // TestERC20 DAI;

    function setUp() public virtual {
        
        // factory = new GenericFactory(admin);

        // evc = new EthereumVaultConnector();

        // protocolConfig = new ProtocolConfig(admin, protocolFeeReceiver);
        // oracle = new MockPriceOracle();
        // unitOfAccount = address(1);
        // integrations = Base.Integrations(address(evc), address(protocolConfig), sequenceRegistry, balanceTracker, permit2);

        // initializeModule = address(new Initialize(integrations));
        // tokenModule = address(new Token(integrations));
        // vaultModule = address(new Vault(integrations));
        // borrowingModule = address(new Borrowing(integrations));
        // liquidationModule = address(new Liquidation(integrations));
        // riskManagerModule = address(new RiskManager(integrations));
        // balanceForwarderModule = address(new BalanceForwarder(integrations));
        // governanceModule = address(new Governance(integrations));

        // modules = Dispatch.DeployedModules({
        //     initialize: initializeModule,
        //     token: tokenModule,
        //     vault: vaultModule,
        //     borrowing: borrowingModule,
        //     liquidation: liquidationModule,
        //     riskManager: riskManagerModule,
        //     balanceForwarder: balanceForwarderModule,
        //     governance: governanceModule
        // });

        // address evaultImpl;
        // evaultImpl = address(new EVault(integrations, modules));

        // vm.prank(admin);
        // factory.setImplementation(evaultImpl);

        // WETH = new TestERC20("Wrapped Ether", "WETH", 18, false);
        // DAI = new TestERC20("Dai Stablecoin", "DAI", 18, false);

        // eWETH = IEVault(
        //     factory.createProxy(address(0), true, abi.encodePacked(address(WETH), address(oracle), unitOfAccount))
        // );
        // eWETH.setHookConfig(address(0), 0);
        // eWETH.setInterestRateModel(address(new IRMTestDefault()));
        // eWETH.setMaxLiquidationDiscount(0.2e4);
        // eWETH.setFeeReceiver(feeReceiver);

        // eDAI = IEVault(
        //     factory.createProxy(address(0), true, abi.encodePacked(address(DAI), address(oracle), unitOfAccount))
        // );
        // eDAI.setHookConfig(address(0), 0);
        // eDAI.setInterestRateModel(address(new IRMTestDefault()));
        // eDAI.setMaxLiquidationDiscount(0.2e4);
        // eDAI.setFeeReceiver(feeReceiver);
    }

    address internal SYNTH_VAULT_HOOK_TARGET = address(new MockHook());
    uint32 internal constant SYNTH_VAULT_HOOKED_OPS = OP_DEPOSIT | OP_MINT | OP_REDEEM | OP_SKIM | OP_REPAY_WITH_SHARES;

    function createSynthEVault(address asset) internal returns (IEVault) {
        address unitOfAccount = address(1);
        IEVault v = IEVault(
            factory.createProxy(address(0), true, abi.encodePacked(address(asset), address(oracle), unitOfAccount))
        );
        v.setHookConfig(address(0), 0);
        v.setInterestRateModel(address(new IRMTestDefault()));

        v.setInterestFee(1e4);

        v.setHookConfig(SYNTH_VAULT_HOOK_TARGET, SYNTH_VAULT_HOOKED_OPS);

        return v;
    }

    function getSubAccount(address primary, uint8 subAccountId) internal pure returns (address) {
        require(subAccountId <= 256, "invalid subAccountId");
        return address(uint160(uint160(primary) ^ subAccountId));
    }
}



contract MockHook is IHookTarget {
    error E_OnlyAssetCanDeposit();
    error E_OperationDisabled();

    function isHookTarget() external pure override returns (bytes4) {
        return this.isHookTarget.selector;
    }

    // deposit is only allowed for the asset
    function deposit(uint256, address) external view {
        address asset = IEVault(msg.sender).asset();

        // these calls are just to test if there's no RO-reentrancy for the hook target
        IEVault(msg.sender).totalBorrows();
        IEVault(msg.sender).balanceOf(address(this));

        if (asset != caller()) revert E_OnlyAssetCanDeposit();
    }

    // all the other hooked ops are disabled
    fallback() external {
        revert E_OperationDisabled();
    }

    function caller() internal pure returns (address _caller) {
        assembly {
            _caller := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }
}
