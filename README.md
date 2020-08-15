### Requirements
* [Node.js](https://nodejs.org/)
* [Truffle](https://truffleframework.com/)
* [Ganache](https://truffleframework.com/ganache/)
* [MetaMask](https://metamask.io/)
    
### Installation

1. Start Ganache on ``localhost:7545``   

2. Build and migrate smart contracts

```sh
$ cd contracts
$ truffle complie
$ truffle migrate --reset --network development --verbose-rpc
```