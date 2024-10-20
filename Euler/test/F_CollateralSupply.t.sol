// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EVaultTestBase} from "./forkUtils/testBase/EVaultTestBase.sol";

import {Events} from "../src/EVault/shared/Events.sol";
import {SafeERC20Lib} from "../src/EVault/shared/lib/SafeERC20Lib.sol";
import {Permit2ECDSASigner} from "./forkUtils/mocks/Permit2ECDSASigner.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";
import "../src/EVault/shared/types/Types.sol";

import "forge-std/Test.sol";

contract CollateralSupply is EVaultTestBase {
    using TypesLib for uint256;

    address lender;

    function setUp() public override {
        super.setUp();
        cheat.createSelectFork("eth_mainnet", BLOCK_NUMBER);

        lender = makeAddr("lender");

        // lender
        startHoax(lender);
        deal(address(WETH), lender, type(uint256).max);
        WETH.approve(address(eWETH), type(uint256).max);
    }

    function test_simple_deposit() public {
        uint256 amount = 10 * 1e18;

        uint256 vaultAssetBalanceBefore = WETH.balanceOf(address(eWETH));
        uint256 totalSupplyBefore = eWETH.totalSupply();
        uint256 lenderShareBalanceBefore = eWETH.balanceOf(address(lender));
        uint256 totalAssetsBefore = eWETH.totalAssets();

        eWETH.deposit(amount, lender);

        assertEq(WETH.balanceOf(address(eWETH)) - vaultAssetBalanceBefore, amount);
        assertEq(eWETH.totalSupply() - totalSupplyBefore, amount);
        assertEq(eWETH.balanceOf(lender) - lenderShareBalanceBefore, amount);
        assertEq(eWETH.totalAssets() - totalAssetsBefore, amount);   
    }

    function test_max_deposit() public {
        uint256 vaultAssetBalanceBefore = WETH.balanceOf(address(eWETH));
        uint256 totalSupplyBefore = eWETH.totalSupply();
        uint256 lenderShareBalanceBefore = eWETH.balanceOf(address(lender));
        uint256 totalAssetsBefore = eWETH.totalAssets();

        eWETH.deposit(MAX_SANE_AMOUNT, lender);

        assertEq(WETH.balanceOf(address(eWETH)) - vaultAssetBalanceBefore, MAX_SANE_AMOUNT);
        assertEq(eWETH.totalSupply() - totalSupplyBefore, MAX_SANE_AMOUNT);
        assertEq(eWETH.balanceOf(lender) - lenderShareBalanceBefore, MAX_SANE_AMOUNT);
        assertEq(eWETH.totalAssets() - totalAssetsBefore, MAX_SANE_AMOUNT);
    }
}
