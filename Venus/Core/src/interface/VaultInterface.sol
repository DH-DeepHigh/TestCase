// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface VaultInterface{
    function xvsBalance() external returns (uint);
    function accXVSPerShare() external returns (uint);
    function pendingRewards() external returns (uint);
    function userInfo(address) external returns (uint, uint);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function claim() external;
    function claim(address account) external;
    function pendingXVS(address _user) external view returns (uint256);
    function updatePendingRewards() external;
    function withdraw() external;
    //admin function 
    function admin() external returns(address);
    function pause() external;
    function resume() external;
    function pendingAdmin() external returns(address);
    function vaiVaultImplementation() external returns(address);
    function pendingVAIVaultImplementation() external returns(address);

    function _become(address vaiVaultProxy) external;
    function setAccessControl(address newAccessControlAddress) external;
    function getAccruedInterest(address) external returns(uint);
    function lastAccruingBlock() external returns(uint);
     function setLastAccruingBlock(uint256 _lastAccruingBlock) external;
}

interface XVSVaultInterface{

    function pause() external;
    function resume() external;
    function poolLength(address rewardToken) external view returns (uint256);
    function rewardTokenAmountsPerBlock(address rewardToken) external view returns (uint256);
    function add(
        address rewardToken,
        uint256 allocPoint,
        address token,
        uint256 rewardPerBlockOrSecond,
        uint256 lockPeriod
    ) external;
    function set(address rewardToken, uint256 pid, uint256 allocPoint) external;
    function setRewardAmountPerBlockOrSecond(address rewardToken, uint256 rewardAmount) external;
    function setWithdrawalLockingPeriod(address rewardToken, uint256 pid, uint256 newPeriod) external;
    function deposit(address rewardToken, uint256 pid, uint256 amount) external;
    function claim(address account, address rewardToken, uint256 pid) external;
    function requestWithdrawal(address rewardToken, uint256 pid, uint256 amount) external;


    function executeWithdrawal(address rewardToken, uint256 pid) external;

    function pendingReward(address rewardToken, uint256 pid, address user) external view returns (uint256);
    function getUserInfo(
        address rewardToken,
        uint256 pid,
        address user
    ) external view returns (uint256 amount, uint256 rewardDebt, uint256 pendingWithdrawals);
    function updatePool(address rewardToken, uint256 pid) external;
    
    struct PoolInfo {
        address token;            
        uint256 allocPoint;       
        uint256 lastRewardBlockOrSecond; 
        uint256 accRewardPerShare; 
        uint256 lockPeriod;        
    }

    function poolInfos(address _rewardToken, uint256 _pid) external view returns (
        address token,
        uint256 allocPoint,
        uint256 lastRewardBlockOrSecond,
        uint256 accRewardPerShare,
        uint256 lockPeriod
    );
    function getEligibleWithdrawalAmount(address,uint,address) external returns(uint);
}


