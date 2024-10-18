// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {EVaultTestBase} from "../forkUtils/testBase/EVaultTestBase.sol";
import {Events} from "../src/EVault/shared/Events.sol";
import {SafeERC20Lib} from "../src/EVault/shared/lib/SafeERC20Lib.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {IRMMax} from "./forkUtils/mocks/IRMMax.sol";
import {IRMTestFixed} from "./forkUtils/mocks/IRMTestFixed.sol";
import {IRMFailed} from "./forkUtils/mocks/IRMFailed.sol";
import {IRMOverBound} from "./forkUtils/mocks/IRMOverBound.sol";
import {Events as EVCEvents} from "ethereum-vault-connector/Events.sol";
import "forge-std/Test.sol";

import "../src/EVault/shared/types/Types.sol";
import "../src/EVault/shared/Constants.sol";

contract Test_CollateralWithdraw is EVaultTestBase {  
    using stdStorage for StdStorage;
    using TypesLib for uint256;

    address lender;
    address borrower;

    function setUp() public {
        super.setUp();

        lender = makeAddr("lender");
        borrower = makeAddr("borrower"); 

        vm.startPrank(lender);
        deal(address(DAI), lender, type(uint256).max);
        DAI.approve(address(DAI), type(uint256).max);
        eDAI.deposit(10_000 * 1e18);

        vm.startPrank(borrower);
        deal(address(WETH), lender, type(uint256).max);
        WETH.approve(address(WETH), type(uint256).max);
        eWETH.deposit(10 * 1e18);
    }

    function test_
}