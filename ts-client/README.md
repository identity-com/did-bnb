# DID bnb typescript client

## Local Integration Test Setup
This repository uses `jest` to run integration test. These test will run against whatever `RPC_URL` is provided in the `.env` file.

To run the integration test navigate to the `ts-client` directory and run `yarn jest`

### Testing with Foundry
Foundry has a built in testnet node called `anvil`. You can first download foundry by following the [steps here](https://book.getfoundry.sh/getting-started/installation).

Once foundry is installed run the command in a terminal to start the node:

```anvil```

Lastly update the `RPC_URL` variable in your `.env` file to `http://127.0.0.1:8545`.

