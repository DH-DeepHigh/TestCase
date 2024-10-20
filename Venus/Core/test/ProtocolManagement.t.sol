pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../src/VenusUtils.sol";
import "../src/TestFile.sol";

/// @notice Example contract that calculates the account liquidity.
contract ProtocolManagementTest is Test, VenusUtils {
    address payable user =payable(makeAddr('user'));
    address pauseGuardian;

    function setUp() public {
        // Fork mainnet at block 20_941_968.
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        pauseGuardian = comptroller.pauseGuardian();
    }
    function test_setPriceOracle() public {
        vm.startPrank(admin);
        comptroller._setPriceOracle(address(0x1));
        assertEq(comptroller.oracle(), address(0x1));
        vm.stopPrank();
        
        vm.expectRevert("only admin can");
        comptroller._setPriceOracle(address(0x2));
    }
    function test_setCloseFactor() public {
        vm.startPrank(admin);
        comptroller._setCloseFactor(4e17);
        assertEq(comptroller.closeFactorMantissa(), 4e17);
        vm.stopPrank();
        
        vm.expectRevert("only admin can");
        comptroller._setCloseFactor(1e18);
    }
    function test_setCollateralFactor() public {
        vm.startPrank(admin);
        (,uint collateralFactor)=comptroller.markets(address(vBNB));
        comptroller._setCollateralFactor(vBNB, collateralFactor + 1);
        
        //return errorcode
        uint result = comptroller._setCollateralFactor(vBNB, 0.9e18 + 1);
        // 6 => INVALID_COLLATERAL_FACTOR  8 => SET_COLLATERAL_FACTOR_VALIDATION
        assertEq(result,6);
        
        //return errorcode
        vm.expectRevert("market not listed");
        comptroller._setCollateralFactor(VTokenInterface(address(0x1)), 0.9e18 + 1);
        vm.stopPrank();
        
        vm.expectRevert("access denied");
        comptroller._setCollateralFactor(vBNB, collateralFactor+2);
    }
    
    function test_setLiquidationIncentive() public {
        vm.startPrank(admin);
        comptroller._setLiquidationIncentive(1e18 + 1);
        assertEq(comptroller.liquidationIncentiveMantissa(), 1e18 + 1);
        vm.stopPrank();
        
        vm.expectRevert("access denied");
        comptroller._setLiquidationIncentive(1e18 + 2);
    }

    function test_supportMarket() public {
        vm.startPrank(admin);

        testToken deploy = new testToken();
        VTokenInterface newCToken = VTokenInterface(deploy);

        comptroller._supportMarket(newCToken);

        //return errorcode
        uint result = comptroller._supportMarket(vBNB);
        //emit Failure(: 10, : 17, : 0) 10 => MARKET_ALREADY_LISTED, 17 => SUPPORT_MARKET_EXISTS
        assertEq(result,10);
        vm.stopPrank();
        
        vm.expectRevert("access denied");
        comptroller._supportMarket(newCToken);
    }
    function test_setMarketBorrowCaps() public {
        VTokenInterface[] memory VToken =new VTokenInterface[](1);
        VToken[0]=vBNB;
        uint[] memory newBorrowCaps = new uint[](1);
        newBorrowCaps[0]=1e18;

        uint[] memory wrongBorrowCaps = new uint[](2);
        wrongBorrowCaps[0]=1e18;
        wrongBorrowCaps[1]=2e18;
        
        vm.startPrank(admin);
        comptroller._setMarketBorrowCaps(VToken, newBorrowCaps);

        vm.expectRevert("invalid input");
        comptroller._setMarketBorrowCaps(VToken, wrongBorrowCaps);
        
        vm.stopPrank();

        vm.expectRevert("access denied");
        comptroller._setMarketBorrowCaps(VToken, newBorrowCaps);
    }

    function test_setPauseGuardian() public {
        vm.startPrank(admin);
        comptroller._setPauseGuardian(user);
        assertEq(comptroller.pauseGuardian(),user);
        vm.stopPrank();

        vm.expectRevert("only admin can");
        comptroller._setPauseGuardian(address(0x1));  
    }
   
    function test_become() public {
        address uni = unitroller.admin();
        testComptroller deploy = new testComptroller();

        vm.startPrank(uni);
        unitroller._setPendingImplementation(address(deploy));
        vm.stopPrank();

        vm.startPrank(uni);
        (bool success,)=address(deploy).call(abi.encodeWithSignature("_become(address)", address(unitroller)));
        assertEq(success,true);
        vm.stopPrank();
    }
    function test_setPendingImplementation_1() public {
        vm.startPrank(master);
        vBNB._setPendingAdmin(user);
        assertEq(vBNB.pendingAdmin(),user);
        vm.stopPrank();

        vm.startPrank(user);
        vBNB._acceptAdmin();
        assertEq(vBNB.admin(),user);
        vm.stopPrank();
    }
    function setComptroller() public { 
        vm.startPrank(admin);
        testComptroller deploy = new testComptroller();
        ComptrollerInterface newComptroller = ComptrollerInterface(deploy);
        
        vBNB._setComptroller(newComptroller);
        assertEq(vBNB.comptroller(),address(newComptroller));

        vm.expectRevert();
        vBNB._setComptroller(ComptrollerInterface(address(1)));
        
        vm.stopPrank();
    }
    function test_setReserveFactor() public {
        vm.startPrank(master);
        // reserveFactorMaxMantissa => 1e18
        uint Factor=vBNB.reserveFactorMantissa();
        
        vBNB._setReserveFactor(1e18);
        assertEq(vBNB.reserveFactorMantissa(), 1e18);

        vBNB._setReserveFactor(Factor + 1);
        assertEq(vBNB.reserveFactorMantissa(), Factor+1);
        
        //return errorcode
        uint result = vBNB._setReserveFactor(1e18 + 1);
        
        //emit Failure(2, 73, 0) 2 => Comptroller rejection, 73 => SET_RESERVE_FACTOR_VALIDATION
        assertEq(result, 2);
    }
    function test_setReduceReserves() public {
        vm.startPrank(admin);
        uint beforeTransfer=dai.balanceOf(proxy);
        
        vDAI._reduceReserves(1);

        uint afterTransfer=dai.balanceOf(proxy);
        assertEq(afterTransfer - beforeTransfer ,1);
        
        //return errorcode
        uint result = vDAI._reduceReserves(type(uint).max);
        //Errorcode => TOKEN_INSUFFICIENT_ALLOWANCE
        assertEq(result, 14);
        vm.stopPrank();
    }
    function test_setInterestRateModel() public {
        vm.startPrank(master);
        
        testInterestRateModel deploy = new testInterestRateModel();
        InterestRateModel newModel = InterestRateModel(deploy);

        vBNB._setInterestRateModel(newModel);
        assertEq(vBNB.interestRateModel(),address(newModel));

        vm.expectRevert();
        // require(newInterestRateModel.isInterestRateModel(), "marker method returned false");
        vBNB._setInterestRateModel(InterestRateModel(address(0x31337)));
        
        vm.stopPrank();
    }

    function test_vToken_resignImplementation() public {
        vm.startPrank(admin);
        vDAI._resignImplementation();
        vm.stopPrank();

        vm.expectRevert("only the admin may call _resignImplementation");
        vDAI._resignImplementation();
    }

    function test_vToken_becomeImplementation() public {
        vm.startPrank(admin);
        vDAI._becomeImplementation(bytes("test"));
        vm.stopPrank();

        vm.expectRevert("only the admin may call _becomeImplementation");
        vDAI._becomeImplementation(bytes("test"));
    }

    function test_vToken_setImplementation() public {
        vm.startPrank(admin);
        vDAI._setImplementation(address(0x31337),false,bytes("test"));
        assertEq(vDAI.implementation(),address(0x31337));

        vDAI._setImplementation(address(0x4567),true,bytes("test"));
        assertEq(vDAI.implementation(),address(0x4567));
        vm.stopPrank();

        vm.expectRevert("VBep20Delegator::_setImplementation: Caller must be admin");
        vDAI._setImplementation(address(0x4567),true,bytes("test"));
    }
     function test_setPendingImplementation_2() public {
        vm.startPrank(admin);
        unitroller._setPendingImplementation(address(0x31337));
        assertEq(unitroller.pendingComptrollerImplementation(),address(0x31337));
        vm.stopPrank();
        
        //return errorcode
        uint result = unitroller._setPendingImplementation(address(0x31337));
        // emit Failure(: 1, : 15, : 0) 1=> UNAUTHORIZED 15=> SET_PENDING_IMPLEMENTATION_OWNER_CHECK
        assertEq(result,1);
    }
    function test_acceptImplementation() public {
        vm.startPrank(admin);
        unitroller._setPendingImplementation(address(0x31337));

        //return errorcode 
        uint result = unitroller._acceptImplementation();
        //emit Failure(: 1, : 1, : 0) 1=> UNAUTHORIZED 1=> ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK
        assertEq(result,1);
        vm.stopPrank();

        vm.startPrank(address(0x31337));
        unitroller._acceptImplementation();
        assertEq(unitroller.comptrollerImplementation(),address(0x31337));
        vm.stopPrank();
    }
    function test_setPendingAdmin() public{
        vm.startPrank(admin);
        unitroller._setPendingAdmin(user);
        assertEq(unitroller.pendingAdmin(),user);
        vm.stopPrank();

        // return errorcode
        uint result = unitroller._setPendingAdmin(user);
        //emit Failure(: 1, : 14, : 0) 1=> UNAUTHORIZED 14=> SET_PENDING_ADMIN_OWNER_CHECK
        assertEq(result,1);
    }
    function test_acceptAdmin() public {
        vm.startPrank(admin);
        unitroller._setPendingAdmin(user);

        //return errorcode 
        uint result = unitroller._acceptAdmin();
        //emit Failure(: 1, : 0, : 0)1=> UNAUTHORIZED 1=> ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK
        assertEq(result,1);
        vm.stopPrank();

        vm.startPrank(user);
        unitroller._acceptAdmin();
        assertEq(unitroller.admin(),user);
        vm.stopPrank();
    }
    receive() external payable{}
  
}