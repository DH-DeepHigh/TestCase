// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import {ComptrollerInterface} from "./interface/ComptrollerInterface.sol";
import {VTokenInterface,liquidateInterface} from "./interface/VTokenInterface.sol";
import {IBEP20Interface} from "./interface/IBEP20Interface.sol";
import {OracleInterface,ResilientOracleInterface,BoundValidatorInterface} from "./interface/OracleInterface.sol";
import "./interface/VaultInterface.sol";
import "./interface/UnitrollerInterface.sol";

interface CheatCodes {
    function createFork(string calldata, uint256) external returns (uint256);
    function createSelectFork(string calldata, uint256) external returns (uint256);
    function startPrank(address) external;
    function stopPrank() external;
}

contract VenusUtils is Test {
    CheatCodes cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    VTokenInterface vBNB = VTokenInterface(0xA07c5b74C9B40447a954e1466938b865b6BBea36);
    VTokenInterface vDAI = VTokenInterface(0x334b3eCB4DCa3593BCCC3c7EBD1A1C1d1780FBF1);
    VTokenInterface vETH = VTokenInterface(0xf508fCD89b8bd15579dc79A6827cB4686A3592c8);
    VaultInterface VAIVault = VaultInterface(0x0667Eed0a0aAb930af74a3dfeDD263A73994f216);
    VaultInterface VRTVault = VaultInterface(0x98bF4786D72AAEF6c714425126Dd92f149e3F334);
    XVSVaultInterface XVSVault = XVSVaultInterface(0x051100480289e704d20e9DB4804837068f3f9204);

    ComptrollerInterface comptroller = ComptrollerInterface(0xfD36E2c2a6789Db23113685031d7F16329158384);
    UnitrollerInterface unitroller = UnitrollerInterface(0xfD36E2c2a6789Db23113685031d7F16329158384);
    
    IBEP20Interface dai = IBEP20Interface(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3);
    IBEP20Interface vai = IBEP20Interface(0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7);
    IBEP20Interface vrt = IBEP20Interface(0x5F84ce30DC3cF7909101C69086c50De191895883);
    IBEP20Interface xvs = IBEP20Interface(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63);

    BoundValidatorInterface set_price = BoundValidatorInterface(0x6E332fF0bB52475304494E4AE5063c1051c7d735);
    
    IBEP20Interface eth = IBEP20Interface(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    ResilientOracleInterface oracle = ResilientOracleInterface(0x6592b5DE802159F3E74B2486b091D11a8256ab8A);
    liquidateInterface liquidator = liquidateInterface(0x0870793286aaDA55D39CE7f82fb2766e8004cF43);
    address master = 0x9A7890534d9d91d473F28cB97962d176e2B65f1d;
    address admin = 0x939bD8d64c0A9583A7Dcea9933f7b21697ab6396;
    address proxy =0xCa01D5A9A248a830E9D93231e791B1afFed7c446;

    uint256 public constant BLOCK_NUMBER = 43_056_300;
}
