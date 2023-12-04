## Description
To protect token from sniper bots and limit whale wallets activity two mechanisms were implemented in GarbageToken contract.

### Sniper bot protection
To avoid sniping bots from buying tokens in first blocks skyrocketing price there is functionality to totally block token transfers for 5 blocks.

This mechanism is controlled by two variables:

```solidity
uint256 private constant antiBotDelay = 5;
uint256 public antiBotDelayStartBlock;
```

`antiBotDelay` sets for how many blocks after listing transfer should be blocked.

`antiBotDelayStartBlock` stores block from which delay blocks should be calculated.
This value can be set only by `provideLiquidity` function and will contain block when liquidity was provided.

### Holding limit 

To avoid single wallet holding more than 1% of liquidity pool there is holding limit.

It is controlled by following variables and functions
```solidity
uint256 public holdLimit;
uint256 public isHoldLimitActive;

function setHoldLimit(uint256 _newHoldLimit) external onlyOwner;
function turnHoldLimitOn() external onlyOwner;
function turnHoldLimitOff() external onlyOwner;
```

`holdLimit` stores token holding cap for single wallet. Main way of setting value is automatic calculation in `provideLiquidity` function, but while liquidity can be set externally there is also an ability to set this variable manually by owner using `setHoldLimit` function;

`isHoldLimitActive` marks if hold limit is enabled or not. Can be set either during `provideLiquidity` function execution or manually by owner using `turnHoldLimitOn` and `turnHoldLimitOff` functions. 