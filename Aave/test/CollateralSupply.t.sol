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
import "../src/protocol/libraries/helpers/Errors.sol";


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
        deal(address(EUL), user_1, 10 * 1e18);
        vm.prank(user_1);
        WETH.approve(address(Pool), type(uint256).max);
    }

    /**
     * @notice 유저가 WETH를 공급하는 기본적인 시나리오를 테스트합니다.
     */
    function test_supply_simple() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 10 * 1e18);

        vm.stopPrank();
    }

    /**
     * @notice 관리자가 WETH 공급을 중지시킨 후, 공급이 중단되었는지 테스트합니다.
     */
    function test_supply_pause() public {
        vm.prank(ACLAdmin);
        PoolConfigurator.setReservePause(address(WETH), true);

        vm.startPrank(user_1);
        
        vm.expectRevert(bytes(Errors.RESERVE_PAUSED));
        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);

        vm.stopPrank();
    }

    /**
     * @notice 존재하지 않는 마켓(EUL)에 자산을 공급하려 시도하는 경우를 테스트합니다.
     */
    function test_supply_market_exist() public {
        vm.startPrank(user_1);

        EUL.approve(address(Pool), type(uint256).max);
        
        vm.expectRevert();
        Pool.supply(address(EUL), 10 * 1e18, user_1, 0);

        vm.stopPrank();
    }

    /**
     * @notice 자산 공급 시 블록 상태가 최신 상태로 갱신되는지 테스트합니다.
     */
    function test_supply_accrue_block() public {
        vm.startPrank(user_1);

        Pool.supply(address(WETH), 10 * 1e18, user_1, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        assert(ReserveData.lastUpdateTimestamp == block.timestamp);

        vm.stopPrank();
    }

}