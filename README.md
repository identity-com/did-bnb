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

- Testnet: [0x75837371D170Bb8E5b74A968aDe00eDeaf59AD56](https://testnet.bscscan.com/address/0x75837371d170bb8e5b74a968ade00edeaf59ad56#code)


## Developer Notes

### Running unit test
This project uses foundry for writing test. You can run the unit test suite by running:

`forge test`

To run the test and get a test coverage report you can run:

`forge coverage`
