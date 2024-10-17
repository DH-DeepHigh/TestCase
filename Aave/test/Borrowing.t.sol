// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from '../src/dependencies/openzeppelin/contracts/IERC20.sol';
import "../src/interfaces/IPool.sol";
import "../src/interfaces/IPoolAddressesProvider.sol";
import "../src/Mock/TestState.sol";
import "../src/Mock/AddressList.sol";
import "../src/protocol/libraries/types/DataTypes.sol";

contract BorrowingTest is Test {
    IPool Pool = IPool(AddressList.POOL);
    IERC20 WETH = IERC20(AddressList.WETH);
    IERC20 USDT = IERC20(AddressList.USDT);
    address user = TestState.user_1;
    function setUp() public {
        vm.createSelectFork("ETH_RPC_URL", TestState.BLOCK_NUMBER);
    }

    function test_simple_borrow() public {
        vm.startPrank(user);
        deal(address(WETH), user, 1 * 1e18);
        WETH.approve(address(Pool), 1 * 1e18);
        Pool.supply(address(WETH), 1 * 1e18, user, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user);
        assert(MintAWETH == 1 * 1e18);
        Pool.borrow(address(USDT), 10 * 1e8, 2, 0, user);
        uint256 BorrowUSDT = IERC20(address(USDT)).balanceOf(user);
        assert(BorrowUSDT == 10 * 1e8);
        vm.stopPrank();
    }
}