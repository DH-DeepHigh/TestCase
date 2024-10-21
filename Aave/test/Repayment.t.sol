// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "../lib/forge-std/src/Test.sol";
import {IERC20} from '../src/dependencies/openzeppelin/contracts/IERC20.sol';
import "../src/interfaces/IPool.sol";
import "../src/interfaces/IPoolAddressesProvider.sol";
import "../src/interfaces/IPoolConfigurator.sol";
import "../src/Mock/TestState.sol";
import "../src/Mock/AddressList.sol";
import "../src/protocol/libraries/types/DataTypes.sol";
import "../src/protocol/libraries/configuration/ReserveConfiguration.sol";
import "../src/protocol/libraries/logic/ReserveLogic.sol";

contract RepaymentTest is Test {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using ReserveLogic for DataTypes.ReserveCache;
    using ReserveLogic for DataTypes.ReserveData;
    IPool Pool;
    IPoolAddressesProvider PoolAddressProvider;
    IPoolConfigurator PoolConfigurator;
    IERC20 WETH;
    IERC20 DAI;
    IERC20 EUL;
    address user_1;
    address user_2;
    address ACLAdmin;
    function setUp() public {
        vm.createSelectFork("ETH_RPC_URL", TestState.BLOCK_NUMBER);

        Pool = IPool(AddressList.POOL);
        PoolAddressProvider = IPoolAddressesProvider(AddressList.POOL_ADDRESSES_PROVIDER);
        PoolConfigurator = IPoolConfigurator(AddressList.POOL_CONFIGURATOR);

        user_1 = TestState.user_1;
        user_2 = TestState.user_2;
        ACLAdmin = PoolAddressProvider.getACLAdmin();

        WETH = IERC20(AddressList.WETH);
        EUL = IERC20(AddressList.EUL);
        DAI = IERC20(AddressList.DAI);

        deal(address(WETH), user_1, 10 * 1e18);

        vm.startPrank(user_1);
        WETH.approve(address(Pool), type(uint256).max);
        DAI.approve(address(Pool), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user_2);
        WETH.approve(address(Pool), type(uint256).max);
        DAI.approve(address(Pool), type(uint256).max);
        vm.stopPrank();
    }

    function test_repay_simple() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 10 * 1e18);

        Pool.borrow(address(DAI), 10_000 * 1e18, 2, 0, user_1);
        uint256 BorrowDAI = IERC20(address(DAI)).balanceOf(user_1);
        assert(BorrowDAI == 10_000 * 1e18);

        DAI.approve(address(Pool), type(uint256).max);
        Pool.repay(address(DAI), 10_000 * 1e18, 2, user_1);
        (, uint256 totalDebtBase, , , ,) = Pool.getUserAccountData(user_1);
        assert(totalDebtBase == 0);
        
        vm.stopPrank();
    }

    function test_repay_market_exist() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 10 * 1e18);

        Pool.borrow(address(DAI), 10_000 * 1e18, 2, 0, user_1);
        uint256 BorrowDAI = IERC20(address(DAI)).balanceOf(user_1);
        assert(BorrowDAI == 10_000 * 1e18);

        EUL.approve(address(Pool), type(uint256).max);
        vm.expectRevert();
        Pool.repay(address(EUL), 10 * 1e18, 2, user_1);
        
        vm.stopPrank();
    }

    function test_repay_accrue_block() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory WETHData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(WETHData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 10 * 1e18);

        Pool.borrow(address(DAI), 10_000 * 1e18, 2, 0, user_1);
        uint256 BorrowDAI = IERC20(address(DAI)).balanceOf(user_1);
        assert(BorrowDAI == 10_000 * 1e18);

        DataTypes.ReserveData memory DAIData = Pool.getReserveData(address(DAI));
        assert(DAIData.lastUpdateTimestamp == block.timestamp);
        
        vm.stopPrank();
    }

    function test_repay_cannot_repay_overDebt() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory WETHData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(WETHData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 10 * 1e18);

        Pool.borrow(address(DAI), 10_000 * 1e18, 2, 0, user_1);
        uint256 BorrowDAI = IERC20(address(DAI)).balanceOf(user_1);
        assert(BorrowDAI == 10_000 * 1e18);

        DAI.approve(address(Pool), type(uint256).max);
        deal(address(DAI), user_1, 100_000 * 1e18);
        Pool.repay(address(DAI), 100_000 * 1e18, 2, user_1);
        uint256 RemainDAI = DAI.balanceOf(user_1);
        assert(RemainDAI == 90_000 * 1e18);

        vm.stopPrank();
    }

}