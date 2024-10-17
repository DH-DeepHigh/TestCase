// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EVaultTestBase} from "./testBase/EVaultTestBase.sol";
import {Events} from "../src/EVault/shared/Events.sol";
import {SafeERC20Lib} from "../src/EVault/shared/lib/SafeERC20Lib.sol";
import {Permit2ECDSASigner} from "./mocks/Permit2ECDSASigner.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";
import "../src/EVault/shared/types/Types.sol";

import "forge-std/Test.sol";

contract Test_CollateralSupply is EVaultTestBase {
    using TypesLib for uint256;

    error InvalidNonce();
    error InsufficientAllowance(uint256 amount);

    uint256 userPK;
    address user;
    address user1;

    Permit2ECDSASigner permit2Signer;

    function setUp() public override {
        super.setUp();

        permit2Signer = new Permit2ECDSASigner(address(permit2));

        user = makeAddr('user');
        user1 = makeAddr('user1');

        assetTST.mint(user1, type(uint256).max / 4);
        hoax(user1);
        assetTST.approve(address(eTST), type(uint256).max);

        assetTST.mint(user, type(uint256).max / 4);
        startHoax(user);
        assetTST.approve(address(eTST), type(uint256).max);
    }

    function test_simple_deposit() public {
        uint256 amount = 1e18;

        eTST.deposit(amount, user);

        assertEq(assetTST.balanceOf(address(eTST)), amount);
        assertEq(eTST.totalSupply(), amount);
        assertEq(eTST.balanceOf(user), amount);
        assertEq(eTST.totalAssets(), amount);
    }

    function test_max_deposit() public {
        // deposit MAX_SANE_AMOUNT
        eTST.deposit(MAX_SANE_AMOUNT, user);

        assertEq(assetTST.balanceOf(address(eTST)), MAX_SANE_AMOUNT);
        assertEq(eTST.totalSupply(), MAX_SANE_AMOUNT);
        assertEq(eTST.balanceOf(user), MAX_SANE_AMOUNT);
        assertEq(eTST.totalAssets(), MAX_SANE_AMOUNT);
    }

    function test_over_deposit() public {
        vm.expectRevert(Errors.E_AmountTooLargeToEncode.selector);
        eTST.deposit(MAX_SANE_AMOUNT + 1, user);
        
        eTST.deposit(MAX_SANE_AMOUNT, user);
        assertEq(assetTST.balanceOf(address(eTST)), MAX_SANE_AMOUNT);

        vm.expectRevert(Errors.E_AmountTooLargeToEncode.selector);
        eTST.deposit(1, user);
    }
    
    function test_direct_transfer() public {
        uint256 amount = 1e18;

        vm.startPrank(user);
        assetTST.transfer(address(eTST), amount);

        assertEq(assetTST.balanceOf(address(eTST)), amount);
        assertEq(eTST.balanceOf(user), 0);
        assertEq(eTST.totalSupply(), 0);
        assertEq(eTST.totalAssets(), 0);

        eTST.deposit(amount, user);

        assertEq(assetTST.balanceOf(address(eTST)), amount * 2);
        assertEq(eTST.balanceOf(user), amount);
        assertEq(eTST.totalSupply(), amount);
        assertEq(eTST.totalAssets(), amount);
    }

    function test_permit2_deposit() public {
        uint256 amount = 1e18;

        // cancel the approval to the vault
        assetTST.approve(address(eTST), 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                SafeERC20Lib.E_TransferFromFailed.selector,
                abi.encodeWithSelector(IAllowanceTransfer.AllowanceExpired.selector, 0),
                abi.encodeWithSignature("Error(string)", "ERC20: transfer amount exceeds allowance")
            )
        );
        eTST.deposit(amount, user);

        // success case
        assetTST.approve(permit2, type(uint160).max);
        IAllowanceTransfer(permit2).approve(address(assetTST), address(eTST), type(uint160).max, type(uint48).max);
        eTST.deposit(amount, user);

        assertEq(assetTST.balanceOf(address(eTST)), amount);
        assertEq(eTST.balanceOf(user), amount);
        assertEq(eTST.totalSupply(), amount);
        assertEq(eTST.totalAssets(), amount);
    }

    function test_batch_permit2_deposit() public {} 
}