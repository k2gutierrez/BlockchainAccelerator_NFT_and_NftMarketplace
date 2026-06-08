### NFT Mock
- I made an ERC721A for better minting options.
- Added a soulbound option which must be called on constructor when deployed, it is immutable.
- Added maxPerWallet function (owner can change it).
- Added mint eth price (owner can set it).
- Max supply immutable so it must be called in the constructor when deployed.

Still missing the tokenURI - I used this as a mock for the NFT Market.

### NFT Market
- Added a fee function which the owner can change.
- Fee basis is of 1000, it is written as a constant.
- Owner can change the fee recipient address.

### Testing
- The initial configuration from the deployment in the test contract is in scripts, there you can change the parameters.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
