// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/VenusUtils.sol";

/// @notice Example contract that calculates the account liquidity.
contract Vault_Test is Test, VenusUtils {
    using stdStorage for StdStorage;
    address user =address(0x1234);
    function setUp() public {
        // Fork mainnet at block 43_056_300.
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(xvs),address(this),2e18);
        deal(address(vai),address(this),2e18);
        deal(address(vrt),address(this),2e18);

        xvs.approve(address(XVSVault),type(uint).max);
        vai.approve(address(VAIVault),type(uint).max);
        vrt.approve(address(VRTVault),type(uint).max);
    }
    function test_XVS_deposit() public {
        uint amount = xvs.balanceOf(address(XVSVault));
        XVSVault.deposit(address(xvs), 0, 1e18);
        // add 1e18
        assertEq(xvs.balanceOf(address(XVSVault)), amount + 1e18);
        
        vm.roll(block.number + 1 );
        
        //rewardDebt must be transfer        
        XVSVault.deposit(address(xvs), 0, 1e18);
        assert(xvs.balanceOf(address(this)) > 0);

        //wrong pid
        vm.expectRevert("vault: pool exists?");
        XVSVault.deposit(address(xvs), 1, 1e18);

    }
    function test_VAI_deposit() public {
        uint amount = vai.balanceOf(address(VAIVault));
        VAIVault.deposit(1e18);
        assertEq(vai.balanceOf(address(VAIVault)), amount + 1e18);

    }
    function test_VRT_deposit() public {
        uint amount = vrt.balanceOf(address(VRTVault));
        VRTVault.deposit(1e18);
        assertEq(vrt.balanceOf(address(VRTVault)), amount + 1e18);
    }

    function test_XVS_withdraw() public{
        XVSVault.deposit(address(xvs), 0, 2e18);
        vm.roll(block.number + 1);
        (uint amount, , )=XVSVault.getUserInfo(address(xvs),0,address(this));
        uint reward=XVSVault.pendingReward(address(xvs), 0, address(this));
        
        //request withdraw => transfer withdraw
        XVSVault.requestWithdrawal(address(xvs),0,amount);
        assertEq(xvs.balanceOf(address(this)),reward);

        vm.expectRevert("nothing to withdraw");
        XVSVault.executeWithdrawal(address(xvs), 0);

        (,,,,uint period) = XVSVault.poolInfos(address(xvs),0);
        
        //withdraw allowed after current timestamp + period 
        vm.warp(block.timestamp + period);
        XVSVault.executeWithdrawal(address(xvs), 0);
        assertEq(xvs.balanceOf(address(this)),amount + reward);
    }
    function test_VAI_withdraw() public{
        VAIVault.deposit(2e18);
        assertEq(vai.balanceOf(address(this)),0);
        VAIVault.withdraw(2e18);
        assertEq(vai.balanceOf(address(this)),2e18);
    }

    function test_VRT_withdraw() public{
        VRTVault.deposit(2e18); 
        assertEq(vrt.balanceOf(address(this)),0);
        VRTVault.withdraw();
        assertEq(vrt.balanceOf(address(this)),2e18);
    }

    function test_XVS_claim() public{
        XVSVault.deposit(address(xvs), 0, 2e18);
        vm.roll(block.number + 1);

        XVSVault.claim(address(this), address(xvs), 0);
        
        //rewardDebt must be transfer
        assert(xvs.balanceOf(address(this)) > 0);
    }
    function test_VAI_claim() public {
        VAIVault.deposit(2e18); 

        //Users receive rewards when pendingRewards increases after making a deposit.
        uint amount = xvs.balanceOf(address(VAIVault));
        deal(address(xvs),address(VAIVault),amount + 20e18);
        VAIVault.updatePendingRewards();

        VAIVault.claim();
        assert(xvs.balanceOf(address(this)) > 2e18);
    }

    function test_VRT_claim() public{
        VRTVault.deposit(2e18);
        vm.roll(block.number + 1000);

        //current block number = 43_056_300  lastAccruingBlock = 29_108_355 
        //set lastAccruingBlock to 43_057_300
        stdstore
            .target(address(VRTVault))
            .sig(VRTVault.lastAccruingBlock.selector)
            .checked_write(uint(43_057_300));
            
        VRTVault.claim();
        
        assert(vrt.balanceOf(address(this)) > 0 );
    }




}