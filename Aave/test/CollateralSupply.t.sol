// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from '../src/dependencies/openzeppelin/contracts/IERC20.sol';
import "../src/interfaces/IPool.sol";
import "../src/interfaces/IPoolAddressesProvider.sol";
import "../src/Mock/TestState.sol";
import "../src/Mock/AddressList.sol";
import "../src/protocol/libraries/types/DataTypes.sol";

contract CollateralSupplyTest is Test {
    IPool Pool = IPool(AddressList.POOL);
    IERC20 WETH = IERC20(AddressList.WETH);
    address user = TestState.user_1;
    function setUp() public {
        vm.createSelectFork("ETH_RPC_URL", TestState.BLOCK_NUMBER);
    }

    function test_simple_supply() public {
        vm.startPrank(user);
        deal(address(WETH), user, 1 * 1e18);
        WETH.approve(address(Pool), 1 * 1e18);
        Pool.supply(address(WETH), 1 * 1e18, user, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user);
        assert(MintAWETH == 1 * 1e18);
        vm.stopPrank();
    }

}