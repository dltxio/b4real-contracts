#B4REAL
## Tests
Hardhat tests can be run via running `yarn test` from the root folder.

## Scripts

### hh:compile
Compiles the contracts with Hardhat

### hh:deploy
Runs the deployment script with the network set in `process.env.NETWORK`.

### hh:node
Starts a local hardhat node with the `localhost` network.

## Configuration
See `/hardhat.config.ts` for hardhat configuration. Some values are fetched from environment variables, see `dev.env` for local development environment variables and copy it into `.env` before changing the values.

## Deployment
The deployment script is located in the `/scripts/deploy` folder. Each contract to be deployed should have its own deployment module.


### Contract addresses
Deployed addresses are saved in `/contracts.json` for each network. This file should be committed so that addresses are managed by git.

## Hardhat Tasks
Tasks are located in the `/scripts/tasks` folder.
A hardhat task allows for easy contract interaction from the command line. To run a contract task, run a command with the following structure:
```
npx hardhat <taskName>
  --network <networkName>
  [--argName <argValue>]
```
For the local hardhat network, use the default `localhost` value for `networkName`. 

## Functions
Below is a table of all non-standard functions
| Function name          | Function description                                                                                    |
|------------------------|---------------------------------------------------------------------------------------------------------|
| setTaxFee              | Sets the fee percentage for the B4REAL Tax fund	(uint256 fee, uint256 feeDecimals) modifiers: onlyAdmin |
| toggleTransactionFees  | Toggles the in-built transaction fee on and off for all transactions modifiers: onlyAdmin               |
| whitelisted            | Whether a wallet has been whitelisted or not                                                            |
| exemptFromFee          | Removes a wallet address to the whitelist modifiers: onlyAdmin, onlyValidAddress                        |
| includeInFee           | Adds a wallet address from the whitelist modifiers: onlyAdmin, onlyValidAddress                         |
| updateB4REALTaxAddress | Updates the tax contract address modifiers: onlyAdmin                                                   |
| calculateFee           | return Number of tokens to hold as the fee                                                              |
| transfer               | Transfers tokens and takes tax when required                                                            |
| setAdmin               | Changes the admin role modifiers: onlyOwner                                                             |
| transferOwnership      | Transfers the owner role modifiers: onlyOwner                                                           |