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
import "../src/protocol/libraries/helpers/Errors.sol";


contract BorrowingTest is Test {
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

    function test_borrow_simple() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory WETHData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(WETHData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 10 * 1e18);

        Pool.borrow(address(DAI), 10_000 * 1e18, 2, 0, user_1);
        DataTypes.ReserveData memory DAIData = Pool.getReserveData(address(DAI));
        address DebtToken = DAIData.variableDebtTokenAddress;
        uint256 BorrowDAI = DAI.balanceOf(user_1);
        uint256 DEBTBalance = IERC20(DebtToken).balanceOf(user_1);
        assert(BorrowDAI == 10_000 * 1e18);
        assert(DEBTBalance == 10_000 * 1e18);

        vm.stopPrank();
    }

    function test_borrow_pause() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 10 * 1e18);
        vm.stopPrank();

        vm.prank(ACLAdmin);
        PoolConfigurator.setReservePause(address(DAI), true);

        vm.prank(user_1);
        vm.expectRevert(bytes(Errors.RESERVE_PAUSED));
        Pool.borrow(address(DAI), 10_000 * 1e18, 2, 0, user_1);

    }

    function test_borrow_market_exist() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 10 * 1e18);

        vm.expectRevert();
        Pool.borrow(address(EUL), 10_000 * 1e18, 2, 0, user_1);

        vm.stopPrank();
    }

    function test_borrow_below_borrow_cap() public {
        // 271000000    dai  BorrowCap
        // 338000000    dai  supplyCap
        // 1400000      WETH BorrowCap
        // 1800000      WETH supplyCap

        deal(address(DAI), user_2, 338_000_000 * 1e18);
        deal(address(WETH), user_1, 1_800_000 * 1e18);

        vm.prank(user_2);
        Pool.supply(address(DAI), 200_000_000 * 1e18, user_1, 0);        

        vm.startPrank(user_1);

        Pool.supply(address(WETH), 500_000 * 1e18, user_1, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 500_000 * 1e18);

        vm.expectRevert(bytes(Errors.BORROW_CAP_EXCEEDED));
        Pool.borrow(address(DAI), 200_000_000 * 1e18, 2, 0, user_1);

        vm.stopPrank();
    }

    function test_borrow_liquidity_check() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory WETHData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(WETHData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 10 * 1e18);

        vm.expectRevert(bytes(Errors.COLLATERAL_CANNOT_COVER_NEW_BORROW));
        Pool.borrow(address(DAI), 2_000_000 * 1e18, 2, 0, user_1);

        vm.stopPrank();
    }

        function test_borrow_accrue_block() public {
        vm.startPrank(user_1);
        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);

        Pool.borrow(address(DAI), 10_000 * 1e18, 2, 0, user_1);
        DataTypes.ReserveData memory DAIData = Pool.getReserveData(address(DAI));
        address DebtToken = DAIData.variableDebtTokenAddress;
        uint256 BorrowDAI = DAI.balanceOf(user_1);
        uint256 DEBTBalance = IERC20(DebtToken).balanceOf(user_1);
        assert(BorrowDAI == 10_000 * 1e18);
        assert(DEBTBalance == 10_000 * 1e18);

        DataTypes.ReserveData memory afterDAIData = Pool.getReserveData(address(DAI));
        assert(afterDAIData.lastUpdateTimestamp == block.timestamp);

        vm.stopPrank();
    }

    function test_borrow_over_market_balance() public {
        DataTypes.ReserveData memory DAIData = Pool.getReserveData(address(DAI));
        uint256 TotalSupply = IERC20(address(DAIData.aTokenAddress)).totalSupply();
        uint256 VariableDebtDai = IERC20(address(DAIData.variableDebtTokenAddress)).balanceOf(address(Pool));
        uint256 MaxBorrowValue = TotalSupply - VariableDebtDai;
        deal(address(WETH), user_1, 1_000_000 * 1e18);

        vm.startPrank(user_1);

        Pool.supply(address(WETH), 100_000 * 1e18, user_1, 0);
        DataTypes.ReserveData memory WETHData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(WETHData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 100_000 * 1e18);

        vm.expectRevert(bytes(Errors.INVALID_AMOUNT));
        Pool.borrow(address(DAI), MaxBorrowValue + 1, 2, 0, user_1);

        vm.stopPrank();

    }

}