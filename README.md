## Reactive Network Demo

## Summary

This project demonstrates the Reactive Network's cross-chain callback mechanism using Foundry for smart contract development. The architecture consists of three main components:

1. **Origin/Destination Contract (`UtilityToken`)** - An ERC20-like token contract deployed on the destination chain (Ethereum Sepolia) that emits transfer events and can receive callbacks from the Reactive Network.

2. **Reactive Contract (`UtilityReactiveContract`)** - Deployed on the Reactive Network, this contract listens for transfer events from the UtilityToken contract and triggers callbacks to the destination chain.

3. **Callback Proxy** - A system contract that facilitates communication between the Reactive Network and destination chains.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DESTINATION CHAIN                                  │
│                         (Ethereum Sepolia)                                   │
│  ┌─────────────────────┐         ┌─────────────────────────────────────┐    │
│  │   UtilityToken      │         │   Callback Proxy Contract           │    │
│  │   (ERC20 Token)     │         │   (Receives callbacks from          │    │
│  │                     │         │    Reactive Network)                │    │
│  │  - transfer()       │         │                                     │    │
│  │  - emits Transfer   │         │  - Forwards callbacks to            │    │
│  │    events           │         │    UtilityToken                     │    │
│  └──────────┬──────────┘         └──────────────────▲──────────────────┘    │
│             │                                       │                        │
└─────────────┼───────────────────────────────────────┼────────────────────────┘
              │ Transfer Event                        │ Callback
              │ (indexed by Reactive Network)         │
              ▼                                       │
┌─────────────────────────────────────────────────────┼────────────────────────┐
│                        REACTIVE NETWORK                                      │
│  ┌──────────────────────────────────────────────────┴───────────────────┐   │
│  │              UtilityReactiveContract                                  │   │
│  │                                                                       │   │
│  │  1. Subscribes to Transfer events from UtilityToken                  │   │
│  │  2. react() function processes indexed events                        │   │
│  │  3. Emits callback to destination chain                              │   │
│  │                                                                       │   │
│  └───────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

1. User calls `transfer()` on the UtilityToken contract
2. Transfer event is emitted and indexed by the Reactive Network
3. UtilityReactiveContract's `react()` function is triggered
4. Reactive contract processes the event and emits a callback
5. Callback Proxy receives and forwards the callback to the destination chain
6. UtilityToken executes the callback logic


### Environment Variables

In order to execute or setup the reactive contracts, we need to first setup the account in the foundry either by copy pasting the private key in the .env or generate the private key using forge cast. More details on how to use forge cast can be found in the [foundry documentation](https://getfoundry.sh/cast/reference/cast/)

Once we have the account setup, make sure to configure the following environment variables:

* `FORGE_ACCOUNT` — Account name for the foundry which we created in the earlier step using `forge cast` command.
* `DESTINATION_RPC` — RPC URL for the destination chain, (see [Chainlist](https://chainlist.org)).
* `DESTINATION_PRIVATE_KEY` — Private key for signing transactions on the destination chain.
* `REACTIVE_RPC` — RPC URL for the Reactive Network (see [Reactive Docs](https://dev.reactive.network/reactive-mainnet)).
* `REACTIVE_PRIVATE_KEY` — Private key for signing transactions on the Reactive Network.
* `DESTINATION_CALLBACK_PROXY_ADDR` — The service address on the destination chain (see [Reactive Docs](https://dev.reactive.network/origins-and-destinations#callback-proxy-address)).

For this example, we are using the Sepolina Testnet. So, fetch the Sepolina Faucet from here (if you haven't already): https://sepolia-faucet.pk910.de

Once you have `SepETH`, need to fetch Reactive Sepolina Faucet (This is needed because Reactive contracts consume `REACT` tokens instead of `SepETH`).
>
> To receive testnet REACT, send SepETH to the Reactive faucet contract on Ethereum Sepolia: `0x9b9BB25f1A81078C544C829c5EB7822d747Cf434`. The factor is 1/100, meaning you get 100 REACT for every 1 SepETH sent.
>
> **Important**: Do not send more than 5 SepETH per request, as doing so will cause you to lose the excess amount without receiving any additional REACT. The maximum that should be sent in a single transaction is 5 SepETH, which will yield 500 REACT.

Now, lets get to the business. 
First load the environment variables by running the following command:

```bash
source .env
```

### Step 1 — Origin/Destination Contract

Deploy the `UtilityToken` contract and assign the `Deployed to` address from the response to `UTILITY_TOKEN_ADDR`.

```bash
forge create --broadcast --rpc-url $DESTINATION_RPC --account $FORGE_ACCOUNT src/contracts/UtilityToken.sol:UtilityToken --constructor-args $DESTINATION_CALLBACK_PROXY_ADDR
```

The above command produces this output
```bash
Deployer: 0xecD0cC6127F01CF483F90cbf123e0FB5c8539A1B
Deployed to: 0x7E0639632A45Adc422ab82F76c08911060fc1A9a
Transaction hash: 0x216df30aba6288d8ff02b4a6a6039cc6a720eec7893c174911d97569f394197c
```

To verify the deployed contract, run the following command

```bash
forge create --broadcast --rpc-url $DESTINATION_RPC --account $FORGE_ACCOUNT src/contracts/UtilityToken.sol:UtilityToken --constructor-args $DESTINATION_CALLBACK_PROXY_ADDR --etherscan-api-key <YOUR_ETHERSCAN_API_KEY> --verify-contract src/contracts/UtilityToken.sol:UtilityToken $DESTINATION_CALLBACK_PROXY_ADDR --chain <YOUR_CHAIN_ID>
```

### Step 2 — Reactive Contract

Deploy the `UtilityReactiveContract` contract and assign the `Deployed to` address from the response to `UTILITY_TOKEN_ADDR`.

```bash
forge create --broadcast --rpc-url $REACTIVE_RPC --account $FORGE_ACCOUNT src/reactive-contracts/UtilityReactiveContract.sol:UtilityReactiveContract --constructor-args $UTILITY_TOKEN_ADDR
```
### Step 3 - Monitor the logs

Once the reactive contract is deployed, we can now monitor the logs/invocation from the Reactive Network to the Destination Network. 
From our example:

1. We have attached the reactive contract to listen to the transfer events of the UtilityToken contract.
2. Once the Reactive Network indexes a transfer event from the UtilityToken contract address, it triggers the reactive contract's `react` function.
3. The reactive contract processes the event and emits a callback.
4. The callback proxy contract receives this callback and forwards it to the destination chain.
5. The destination chain's callback contract executes the specified logic based on the callback data defined in the payload.

Following is the command to invoke the transfer function on the UtilityToken contract:
```bash
cast send $UTILITY_TOKEN_ADDR "transfer(address,uint256)" --rpc-url $DESTINATION_RPC --account $FORGE_ACCOUNT $EOA_ADDRESS $AMOUNT
```

With this, we have successfully demonstrated the callbacks from the Reactive Network to the Destination Network.

## Additional Notes

If the contract on the Reactive Network is marked as INACTIVE, it means that the contract is under funded and needs funding. Execute the below command to fund the contract:

```bash
cast send $REACTIVE_CONTRACT_ADDR --rpc-url $REACTIVE_RPC --account $FORGE_ACCOUNT --value 0.01ether
```

Once the contract is funded, we need to invoke the coverDebt function to clear the debts that the contract has until now.
```bash
cast send --rpc-url $REACTIVE_RPC --account $FORGE_ACCOUNT $REACTIVE_CONTRACT_ADDR "coverDebt()"
```

# Resources
* [Reactive Network Documentation](https://dev.reactive.network/)
* [Foundry Documentation](https://book.getfoundry.sh/)