// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {IERC20} from '../src/dependencies/openzeppelin/contracts/IERC20.sol';
import "../src/interfaces/IPool.sol";
import "../src/interfaces/IPoolAddressesProvider.sol";
import "../src/interfaces/IPoolConfigurator.sol";
import "../src/Mock/TestState.sol";
import "../src/Mock/AddressList.sol";
import "../src/protocol/libraries/types/DataTypes.sol";

contract CollateralSupplyTest is Test {
    IPool Pool;
    IPoolAddressesProvider PoolAddressProvider;
    IPoolConfigurator PoolConfigurator;
    IERC20 WETH;
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

        deal(address(WETH), user_1, 10 * 1e18);
        vm.prank(user_1);
        WETH.approve(address(Pool), type(uint256).max);
    }

    function test_supply_simple() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 10 * 1e18);

        vm.stopPrank();
    }

    function test_supply_pause() public {
        vm.prank(ACLAdmin);
        PoolConfigurator.setReservePause(address(WETH), true);

        vm.startPrank(user_1);
        vm.expectRevert();
        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        vm.stopPrank();
    }

    function test_supply_market_exist() public {
        deal(address(EUL), user_1, 10 * 1e18);
        vm.startPrank(user_1);
        EUL.approve(address(Pool), type(uint256).max);
        
        vm.expectRevert();
        Pool.supply(address(EUL), 10 * 1e18, user_1, 0);
        vm.stopPrank();
    }

    function test_supply_accrue_block() public {
        vm.startPrank(user_1);
        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        assert(ReserveData.lastUpdateTimestamp == block.timestamp);
        vm.stopPrank();
    }

}