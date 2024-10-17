// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/interfaces/IPool.sol";
import "../src/interfaces/IPoolAddressesProvider.sol";
import "../src/Mock/MockValue.sol";
import "../src/Mock/MockAddress.sol";
import {IERC20} from '../src/dependencies/openzeppelin/contracts/IERC20.sol';
import "../src/protocol/libraries/types/DataTypes.sol";

contract CounterTest is Test {
    IPool Pool = IPool(AddressList.POOL);
    IERC20 WBTC = IERC20(AddressList.WBTC);
    address user = TestState.user_1;
    function setUp() public {
        vm.createSelectFork("ETH_RPC_URL", TestState.BLOCK_NUMBER);
    }

    function test_simple_supply() public {
        vm.startPrank(user);
        deal(address(WBTC), user, 100 ether);

        WBTC.approve(address(Pool), 100 ether);
        Pool.supply(address(WBTC), 1 * 1e8, user, 0);
        // DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WBTC));
        // DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(user));
        DataTypes.UserConfigurationMap memory UserConfiguration = Pool.getUserConfiguration(address(user));
        // (uint256 totalCollateralBase,
        // uint256 totalDebtBase,
        // uint256 availableBorrowsBase,
        // uint256 currentLiquidationThreshold,
        // uint256 ltv,
        // uint256 healthFactor) = Pool.getUserAccountData(user);
        // uint256 RewardAWBTC = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user);
        // IERC20 ExpectedLiquidityAWBTC = IERC20(address(ReserveData.aTokenAddress));

        // require(RewardAWBTC == ExpectedLiquidityAWBTC, "");


    }
}