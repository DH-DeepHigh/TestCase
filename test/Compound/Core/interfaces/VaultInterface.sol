// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface VAIVaultInterface{
    function xvsBalance() external returns (uint);
    function accXVSPerShare() external returns (uint);
    function pendingRewards() external returns (uint);
    function userInfo(uint, uint) external returns (address);    
    //admin function 
    function admin() external returns(address);
    function pendingAdmin() external returns(address);
    function vaiVaultImplementation() external returns(address);
    function pendingVAIVaultImplementation() external returns(address);
}