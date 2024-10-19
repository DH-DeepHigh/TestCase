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
### Venus

## +++

각 프로토콜 마다 작성해둔 테스트 코드들이 있는데 해당 테스트 코드들을 참고

- 모든 Lending protocol에 공통적으로 적용할 수 있는 invariant를 정리하는 작업이 먼저 되어야할 것


