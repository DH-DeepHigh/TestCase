# testcase

## Installation

This repo uses [Foundry](https://github.com/foundry-rs/foundry), if you don't have it installed, go [here](https://book.getfoundry.sh/getting-started/installation) for instructions. 

Once you cloned the repo, be sure to be located at the root and run the following command:

```
forge install 
```

## Usage 

All the examples are located under the test folder. 

To test all of them just run the following command: 

```
forge test -vv
```
* An alchemy key is provided, you don't need to add anything. 

To test a specific example run: 
```
forge test --match-path test/name-of-the-file -vv
```
## 테스트케이스 작성 내용

### 1. Compound

|상태|내용|
|--|------|
|완료|기본적인 기능 테스트|
|완료|admin 기능 테스트|
|시작 전|추가적인 테스트|

Location: test/Compoundv2/cEther.t.sol 
  
Location: test/Compoundv2/cErc20.t.sol 

Location: test/Compoundv2/governance.t.sol 

Location: test/Compoundv2/admin_CToken.t.sol

Location: test/Compoundv2/admin_Comptroller.t.sol

Location: test/Compoundv2/admin_Unitroller.t.sol

Location: test/Compoundv2/guardian.t.sol

Location: test/Compoundv2/claimComp.t.sol 

- 현재 compound v2 마켓에서 보상을 지급하지 않아서 따로 compspeed 값 설정 후 진행하였음



