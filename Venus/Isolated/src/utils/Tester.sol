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
import { IResilientOracle } from "../interfaces/IResilientOracle.sol";
import { IBEP20 } from "../interfaces/IBEP20.sol";
import { IERC20 } from "../interfaces/IERC20.sol";

interface CheatCodes {
    function createFork(string calldata, uint256) external returns (uint256);
    function createSelectFork(string calldata, uint256) external returns (uint256);
    function startPrank(address) external;
    function stopPrank() external;
}

contract Tester is Test {
    uint256 public constant BLOCK_NUMBER = 43_186_673;
    CheatCodes cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // BNB Chain Mainnet
    IPoolRegistry poolRegistry = IPoolRegistry(0x9F7b01A536aFA00EF10310A162877fd792cD0666);
    IRiskFund riskFund = IRiskFund(0xdF31a28D68A2AB381D42b380649Ead7ae2A76E42);
    IShortFall shortFall = IShortFall(0xf37530A8a810Fcb501AA0Ecd0B0699388F0F2209);
    IProtocolShareReserve protocolShareReserve = IProtocolShareReserve(0xCa01D5A9A248a830E9D93231e791B1afFed7c446);

    // oracle
    IResilientOracle oracle = IResilientOracle(0x6592b5DE802159F3E74B2486b091D11a8256ab8A);

    // Liquid Staked ETH Pool
    IComptroller comptroller = IComptroller(0xBE609449Eb4D76AD8545f957bBE04b596E8fC529);
    IPancakeswapV2Router swapRouter = IPancakeswapV2Router(0xfb4A3c6D25B4f66C103B4CD0C0D58D24D6b51dC1);
    IBEP20 wstETH = IBEP20(0x26c5e01524d2E6280A48F2c50fF6De7e52E9611C);
    IBEP20 weETH = IBEP20(0x04C0599Ae5A44757c0af6F9eC3b93da8976c150A);
    IBEP20 ETH = IBEP20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    IVToken vwstETH_ = IVToken(0x94180a3948296530024Ef7d60f60B85cfe0422c8);
    IVToken vweETH = IVToken(0xc5b24f347254bD8cF8988913d1fd0F795274900F);
    IVToken vETH = IVToken(0xeCCACF760FEA7943C5b0285BD09F601505A29c05);

    // Pool GameFi
    IComptroller gComptroller = IComptroller(0x1b43ea8622e76627B81665B1eCeBB4867566B963);
    IPancakeswapV2Router gSwapRouter = IPancakeswapV2Router(0x9B15462a79D0948BdDF679E0E5a9841C44aAFB7A);
    IBEP20 RACA = IBEP20(0x12BB890508c125661E03b09EC06E404bc9289040);
    IBEP20 FLOKI = IBEP20(0xfb5B838b6cfEEdC2873aB27866079AC55363D37E);
    IBEP20 USDD = IBEP20(0xd17479997F34dd9156Deef8F95A52D81D265be9c);
    IBEP20 USDT = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    IVToken vRACA = IVToken(0xE5FE5527A5b76C75eedE77FdFA6B80D52444A465);
    IVToken vFLOKI = IVToken(0xc353B7a1E13dDba393B5E120D4169Da7185aA2cb);
    IVToken vUSDD = IVToken(0x9f2FD23bd0A5E08C5f2b9DD6CF9C96Bfb5fA515C);
    IVToken vUSDT = IVToken(0x4978591f17670A846137d9d613e333C38dc68A37);

    // Pool Liquid Staked BNB
    // IComptroller bnbComptroller = IComptroller(0xd933909A4a2b7A4638903028f44D1d38ce27c352);
    // IPancakeswapV2Router bnbSwapRouter = IPancakeswapV2Router(0x5f0ce69Aa564468492e860e8083BB001e4eb8d56);
    // IBEP20 ankrBNB = IBEP20(0x52F24a5e03aee338Da5fd9Df68D2b6FAe1178827);
    // IBEP20 BNBx = IBEP20(0x1bdd3Cf7F79cfB8EdbB955f20ad99211551BA275);
    // IBEP20 stkBNB = IBEP20(0xc2E9d07F66A89c44062459A47a0D2Dc038E4fb16);
    // IBEP20 slisBNB = IBEP20(0xB0b84D294e0C75A6abe60171b70edEb2EFd14A1B);
    // IBEP20 WBNB = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    // IVToken vankrBNB = IVToken(0xBfe25459BA784e70E2D7a718Be99a1f3521cA17f);
    // IVToken vankrBNB = IVToken(0x5E21bF67a6af41c74C1773E4b473ca5ce8fd3791);
    // IVToken vankrBNB = IVToken(0xcc5D9e502574cda17215E70bC0B4546663785227);
    // IVToken vankrBNB = IVToken(0xd3CC9d8f3689B83c91b7B59cAB4946B063EB894A);
    // IVToken vankrBNB = IVToken(0xe10E80B7FD3a29fE46E16C30CC8F4dd938B742e2);

    // Pool Stablecoin
    // IComptroller stableComptroller = IComptroller(0x94c1495cD4c557f1560Cbd68EAB0d197e6291571);
    // IPancakeswapV2Router stableSwapRouter = IPancakeswapV2Router(0xBBd8E2b5d69fcE9Aaa599c50F0f0960AA58B32aA);
    // IBEP20 lisUSD = IBEP20(0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5);
    // IBEP20 USDD = IBEP20(0xd17479997F34dd9156Deef8F95A52D81D265be9c);
    // IBEP20 USDT = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    // IBEP20 EURA = IBEP20(0x12f31B73D812C6Bb0d735a218c086d44D5fe5f89);
    // IVToken vLISUSD = IVToken(0xCa2D81AA7C09A1a025De797600A7081146dceEd9);
    // IVToken vUSDD = IVToken(0xc3a45ad8812189cAb659aD99E64B1376f6aCD035);
    // IVToken vUSDT = IVToken(0x5e3072305F9caE1c7A82F6Fe9E38811c74922c3B);
    // IVToken vEURA = IVToken(0x795DE779Be00Ea46eA97a28BDD38d9ED570BCF0F);
    
    // Pool DeFi

    // Pool Tron
    // IComptroller tronComptroller = IComptroller(0x23b4404E4E5eC5FF5a6FFb70B7d14E3FabF237B0);
    // IPancakeswapV2Router tronSwapRouter = IPancakeswapV2Router(0xacD270Ed7DFd4466Bd931d84fe5B904080E28Bfc);
    // IBEP20 BTT = IBEP20(0x352Cb5E19b12FC216548a2677bD0fce83BaE434B);
    // IBEP20 TRX = IBEP20(0xCE7de646e7208a4Ef112cb6ed5038FA6cC6b12e3);
    // IBEP20 WIN = IBEP20(0xaeF0d72a118ce24feE3cD1d43d383897D05B4e99);
    // IBEP20 USDD_Tron = IBEP20(0xd17479997F34dd9156Deef8F95A52D81D265be9c);
    // IBEP20 USDT_Tron = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    // IVToken vBTT_Tron = IVToken(0x49c26e12959345472E2Fd95E5f79F8381058d3Ee);
    // IVToken vTRX_Tron = IVToken(0x836beb2cB723C498136e1119248436A645845F4E);
    // IVToken vWIN_Tron = IVToken(0xb114cfA615c828D88021a41bFc524B800E64a9D5);
    // IVToken vUSDD_Tron = IVToken(0xf1da185CCe5BeD1BeBbb3007Ef738Ea4224025F7);
    // IVToken vUSDT_Tron = IVToken(0x281E5378f99A4bc55b295ABc0A3E7eD32Deba059);

    // Meme Pool
    // IComptroller memeComptroller = IComptroller(0x33B6fa34cd23e5aeeD1B112d5988B026b8A5567d);
    // IPancakeswapV2Router memeSwapRouter = IPancakeswapV2Router(0x9Db0CBD9A73339949f98C5E6a51e036d0dEaFf21);
    // IBEP20 BabyDoge = IBEP20(0xc748673057861a797275CD8A068AbB95A902e8de);
    // IBEP20 USDT_Meme = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    // IVToken vBabyDoge_Meme = IVToken(0x52eD99Cd0a56d60451dD4314058854bc0845bbB5);
    // IVToken vUSDT_Meme = IVToken(0x4a9613D06a241B76b81d3777FCe3DDd1F61D4Bd0);

    
}