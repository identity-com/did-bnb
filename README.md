# did:bnb

Welcome to the `did:bnb` Method monorepo.

[BNB Smart Chain (BSC)](https://docs.bnbchain.org/docs/learn/intro) is an EVM-compatible Blockchain that operates on a 
combination of DPoS and PoA for consensus. It provides fast finality on transactions.
The BNB DID method is a method for storing DIDs and managing DID documents on BNB Smart Chain.

## Design goals
did:bnb can draw from the previous work on EVM-based did methods. The following are the design goals for did:bnb:

- **Generative**: DID Documents are automatically generated from its identifier if no on-chain state exists. This allows for the creation of a DID without the need for a transaction.
- **Key Ownership Flag**: A Verification Method can have an ownership flag that indicates that the given key was proven to the chain by the controller.
- **Recovery key**: A Verification Method can be marked as a recovery method. This protects it from being removed from the DID Document by OTHER authoritative keys.
- **(TBD) Controller Relationship**: Allows another did:bnb DID to be the controller of the DID.
- **Additional Key Support**: Supports keys other than secp256k1. Specifically ed25519. However these can never have an "Ownership" Proof
- **Lockout Protection**: A DID must always have a valid key with Ownership Proof.
- **Persistence**: DID Documents are stored on-chain and can be retrieved by any client. There is no block or time-limit or the persisted data.
- **Goverance**: did:bnb Smart Contract is gonvered by BNB Beacon Chain.


## Creating DIDs

*Any ethereum public key can be a DID.* This means that if you have a public key `0xabc`, then that key
corresponds to the decentralized identifier `did:bnb:0xabc`.

This DID is called a `generative` DID, because it is generated from a public key, and has no other information associated with it.

Generative DIDs have one authority, which is the public key itself (`0xabc` in this case).

## Updating DIDs

In order to add more authorities, or any other information to the DID it must be initialised on chain, the `initializeDidState` function must be called first.

Once a DID is initialized new verification methods, services and controllers can be added/removed from the DIDs state.

## DID State
The state of a DID is stored in a mapping `didStates` where the keys are public keys coressponding to didIdentifiers and the values are a struct representing the state of a DID.

 `mapping(address => DidState) private didStates;`

 ```
 struct DidState {
        VerificationMethod[] verificationMethods;
        Service[] services;
        address[] nativeControllers;
        string[] externalControllers;
    }
 ```

## Contract Functions

### `resolveDidState`
Returns the state of a given did

Arguments:
- address: `didIdentifier`

Returns:
- DidState: `didState`

### `initializeDidState`
Initalizes a DID with the default state and persist it on-chain.

Arguments:
- address: `didIdentifier`

### `isGenerativeDidState`

Arguments:
- address: `didIdentifier`

Returns:
- bool: `isGenerative`

### `addVerificationMethod`
Attempts to add a verification method to a DIDs state with the following contraints:

1. Fragments used for naming verification methods must be unique.

2. A verification method cannot be create with the ownership OR protected flags.

Arguments:
- address: `didIdentifier`
- VerificationMethod: `verificationMethod`

Event Emitted: `VerificationMethodAdded`

### `removeVerificationMethod`
Attempts to remove a verification method from a DIDs state with the following contraints:

1. A DID must always have at least 1 verification method with the `CAPABILITY_INVOCATION` flag.

2. A verification method cannot be removed if it has the `PROTECTED` flag.

Arguments:
- address: `didIdentifier`
- string: `fragment`

Event Emitted: `VerificationMethodRemoved`

### `updateVerificationMethodFlags`
Attempts to update a verification methods flags on a DIDs state with the following contraints:

1. If trying to change the `OWNERSHIP_PROOF` or `PROTECTED` flags the keyData must match the message sender.

2. A DID must always have at least 1 verification method with the `CAPABILITY_INVOCATION` flag.

Arguments:
- address: `didIdentifier`
- string: `fragment`
- u16: `flags`

Event Emitted: `VerificationMethodFlagsUpdated`

### `addService`
Attempts to add a service to a DIDs state with the following contraints:

1. Fragments used for naming verification methods must be unique.

Arguments:
- address: `didIdentifier`
- Service: `service`

Event Emitted: `ServiceAdded`

### `removeService`
Attempts to remove a service from a DIDs state.

Arguments:
- address: `didIdentifier`
- string: `fragment`

Event Emitted: `ServiceRemoved`

### `addNativeController`
Attempts to add a controller to a DIDs state with the following contraints:

1. No duplicate controllers are allowed

Arguments:
- address: `didIdentifier`
- address: `nativeController`

Event Emitted: `ControllerAdded`

### `removeNativeController`
Attempts to remove a controller from a DIDs state.

Arguments:
- address: `didIdentifier`
- address: `nativeController`

Event Emitted: `ControllerRemoved`

### `addExternalController`
Attempts to add a controller to a DIDs state with the following contraints:

1. No duplicate controllers are allowed

Arguments:
- address: `didIdentifier`
- string: `controller`

Event Emitted: `ControllerAdded`

### `removeExternalController`
Attempts to remove a controller from a DIDs state.

Arguments:
- address: `didIdentifier`
- string: `controller`

Event Emitted: `ControllerRemoved`

## Deployments

- Testnet: [0x88a05b4370BbB90c9F3EEa72A65c77131a7bc18d](https://testnet.bscscan.com/address/0x88a05b4370BbB90c9F3EEa72A65c77131a7bc18d)


## Developer Notes

### Running unit test
This project uses foundry for writing test. You can run the unit test suite by running:

`forge test`

To run the test and get a test coverage report you can run:

`forge coverage`


### Contract deployment
This project uses hardhat scripts in combination with [Openzeppelin defender](https://www.openzeppelin.com/defender) and a multi-sig wallet (both on testnet and mainnet) for contract deployments. All deployment transactions occur through a [relayer](https://docs.openzeppelin.com/defender/v2/manage/relayers) and once deployed ownership of all contracts is transferred to the multi-sig wallet that is also managed in Defender.

This project also uses BnB's explorer api key to verify contracts.

#### Bnb testnet
Deployments are automatically triggered on every merge to the `main` branch via a github action and can also be run manually. Before deployments please ensure the relayer has enough testnet BNB. You can get more testnet bnb at [this faucet](https://testnet.bnbchain.org/faucet-smart).

- Relayer address: [0x8785567484518943B3eeB59882Ab9199994d04bF](https://testnet.bscscan.com/address/0x8785567484518943B3eeB59882Ab9199994d04bF)

- DidRegistry proxy address: 0x88a05b4370BbB90c9F3EEa72A65c77131a7bc18d

#### Bnb mainnet
Deployments are manually triggered via a github action. Before deployments please ensure the relayer has enough BNB. 

- Relayer address: 0xF4550214AA98a7DE728F4eAef0672cD0D2F10B2a

- DidRegistry proxy address: [0x3e366D776150c63Eb53C6675734070696403BEe9](https://bscscan.com/address/0x3e366D776150c63Eb53C6675734070696403BEe9)


#### Local deployment
To deploy locally you first start the anvil node by running `anvil`, then you can run the local deployment script `npm run local-deployment` or `yarn local-deployment`