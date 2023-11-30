## Content

Repo contains contracts for Garbage.
Contracts were developed using foundry.

## Repo structure
- /script - deployment scripts
- /src - contracts code
  - /interfaces - interfaces used in contracts
  - /test - special versions of contracts for deployment to testnet
- /test - tests


## Contracts

### GarbageSale
Contract for selling tokens for static price in 0.02 USDT. Purchase happens by transferring ether to contract.
### GarbageSaleV2
Contract is designed to take into account some details that were missed in first version and replace it taking into account actual v1 state.
### GarbageToken
ERC20 token contract with additional functionality.
This contract have functions for listing itself on Uniswap and providing liquidity.
To protect contract from sniping bots all transfer can be blocked for 5 blocks after providing liquidity.
To avoid single wallet from holding more than 1% there is hold limit functionality that can be enabled or disabled manually by owner.
After providing liquidity contract can optionally enable bot protection and holding limit.
### GarbageClaim
Coming soon


## Using repo
### Preparations
Firstly you need to install [rust](https://www.rust-lang.org/) and [foundry](https://book.getfoundry.sh/getting-started/installation). After this you should install all dependencies with following command:
``` bash
forge install
```
After dependencies are installed you should configure envs, all necessary env variables are listed in [`.env.example`](.env.example) file.
### Building 
To compile contracts you should run following command: 
``` bash 
forge build
```
All build artifacts will be in `/out` folder.
### Testing
Tests could be run with next commands.

For running all tests:

``` bash
forge test
```
For running GarbageSale tests:

``` bash
forge test --match-contract GarbageSaleTestSuit
```
For running GarbageSaleV2 tests:

``` bash
forge test --match-contract GarbageSaleV2TestSuit
```
For running GarbageToken tests:
> GarbageToken tests use mainnet fork, you should set **MAINNET_RPC_URL** env variable before running them. 
> 
> Also be ready to wait some time while fork tests are running
``` bash
forge test --match-contract GarbageTokenTestSuite
```