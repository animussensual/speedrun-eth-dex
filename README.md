# 🏗 scaffold-eth | 🏰 BuidlGuidl

Challenges from [speedruneth](https://speedrunethereum.com/)

## 🚩 Challenge 5: Minimum Viable Exchange

Implementation of [scaffold-eth dex challenge](https://github.com/scaffold-eth/scaffold-eth-challenges/tree/challenge-5-dex)

Original tutorial is available here - [original tutorial](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90)

### Rinkeby

* [DEX](https://rinkeby.etherscan.io/address/0xd374858ffdd6938062724a55b42fee217988e783)
* [Token](https://rinkeby.etherscan.io/address/0x0A615b8ad6a1578aE2e5fFf4F145dF82d1186989)

### DEX logic (Automated Market Maker for single trading pair)

DEX allows to swap between ETH and Balloon tokens.

* It is implemented as Constant Function Market Maker: x * y = k. At any time constant k stays the same while x and y change.
x and y are the amounts of each token in the pool.
* k changes only when more liquidity is added or removed.
* For example Uniswap v1 whitepaper describes it here [Uniswap V1](https://github.com/runtimeverification/verified-smart-contracts/blob/uniswap/uniswap/x-y-k.pdf)

#### Pairs
* ETH
* Balloon(BAL)

### 🔭 Environment 📺

You'll have three terminals up for:

`yarn start` (react app frontend)

`yarn chain` (hardhat backend)

`yarn deploy` (to compile, deploy, and publish your contracts to the frontend)

`yarn test` (runs tests locally)
