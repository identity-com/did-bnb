# did:bnb

Welcome to the `did:bnb` Method monorepo.

[BNB Smart Chain (BSC)](https://docs.bnbchain.org/docs/learn/intro) is an EVM-compatible Blockchain that operates on a 
combination of DPoS and PoA for consensus. It provides fast finality on transactions.
The BNB DID method is a method for storing DIDs and managing DID documents on BNB Smart Chain.

## Creating DIDs

*Any ethereum public key can be a DID.* This means that if you have a public key `abc`, then that key
corresponds to the decentralized identifier `did:bnb:abc`.

This DID is called a `generative` DID, because it is generated from a public key, and has no other information associated with it.

Generative DIDs have one authority, which is the public key itself (`abc` in this case).

## Updating DIDs

In order to add more authorities, or any other information to the DID it must be initialised on chain,
using the `initializeDidState` function.

Once a DID is initialized new verification methods, services and controllers can be added/removed from the DIDs state.



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

### Deployments

- Testnet: [0x75837371D170Bb8E5b74A968aDe00eDeaf59AD56](https://testnet.bscscan.com/address/0x75837371d170bb8e5b74a968ade00edeaf59ad56#code)

