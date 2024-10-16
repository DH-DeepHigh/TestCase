// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import { IPoolRegistry } from "../interfaces/IPoolRegistry.sol";
import { IRiskFund } from "../interfaces/IRiskFund.sol";
import { IShortFall } from "../interfaces/IShortFall.sol";
import { IProtocolShareReserve } from "../interfaces/IProtocolShareReserve.sol";
import { IComptroller } from "../interfaces/IComptroller.sol";
import { IVToken } from "../interfaces/IVToken.sol";
import { IPancakeswapV2Router } from "../interfaces/IPancakeswapV2Router.sol";

interface CheatCodes {
    function createFork(string calldata, uint256) external returns (uint256);
    function createSelectFork(string calldata, uint256) external returns (uint256);
    function startPrank(address) external;
    function stopPrank() external;
}

contract TestUtil is Test {
    uint256 public constant BLOCK_NUMBER = 43_056_300;
    CheatCodes cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // // BNB Chain Mainnet
    address DefaultProxyAdmin = 0x6beb6D2695B67FEb73ad4f172E8E2975497187e4;
    IPoolRegistry poolRegistry = IPoolRegistry(0x9F7b01A536aFA00EF10310A162877fd792cD0666);
    IRiskFund riskFund = IRiskFund(0xdF31a28D68A2AB381D42b380649Ead7ae2A76E42);
    IShortFall shortFall = IShortFall(0xf37530A8a810Fcb501AA0Ecd0B0699388F0F2209);
    IProtocolShareReserve protocolShareReserve = IProtocolShareReserve(0xCa01D5A9A248a830E9D93231e791B1afFed7c446);

    // Pool Stablecoin
    IComptroller stableComptroller = IComptroller(0x94c1495cD4c557f1560Cbd68EAB0d197e6291571);
    IPancakeswapV2Router stableSwapRouter = IPancakeswapV2Router(0xBBd8E2b5d69fcE9Aaa599c50F0f0960AA58B32aA);
    IVToken vLISUSD = IVToken(0xCa2D81AA7C09A1a025De797600A7081146dceEd9);
    IVToken vUSDD = IVToken(0xc3a45ad8812189cAb659aD99E64B1376f6aCD035);
    IVToken vUSDT = IVToken(0x5e3072305F9caE1c7A82F6Fe9E38811c74922c3B);
    IVToken vEURA = IVToken(0x795DE779Be00Ea46eA97a28BDD38d9ED570BCF0F);
    
}