# `did:bnb` Client

A typescript client library for registering, manipulating, and resolving DIDs
using the `did:bnb` method.

## Features
The `@identity.com/did-bnb-client` library provides the following features:

1. A W3C [DID core spec (v1.0)](https://www.w3.org/TR/did-core/) compliant DID method and resolver operating on the Binance Smart Chain (BSC).
2. TS Client for creating, manipulating, and resolving `did:bnb`.
3. Generic Support for VerificationMethods of any Type and Key length.
4. Native on-chain support for `EcdsaSecp256k1RecoveryMethod2020`.
5. A web-service driver, compatible with [uniresolver.io](https://unresolver.io) and [uniregistrar.io](https://uniregistrar.io).
6. Introduced `OWNERSHIP_PROOF` to indicate that a Verification Method Key signature was verified on-chain.
7. Introduced `DID_DOC_HIDDEN` flag that enables hiding a Verification Method from the DID resolution.

## Client library
### Installation
In the command line of the project folder, type the following and then press **Enter**:
```shell
yarn add @identity.com/did-bnb-client #
```

or

```shell
npm install @identity.com/did-bnb-client
```

### Contract Addresses
The BNB DID Registry contract is deployed at the following address (via proxy):
- Testnet: [0x88a05b4370BbB90c9F3EEa72A65c77131a7bc18d](https://testnet.bscscan.com/address/0x88a05b4370BbB90c9F3EEa72A65c77131a7bc18d)
- Mainnet: TODO

### Usage - Setup and Resolution
Create a service for a `did:bnb` by using the following code snippet:

#### Via Provider (read-only)
```typescript
const address = "0x88a05b4370BbB90c9F3EEa72A65c77131a7bc18d";
const provider = getDefaultProvider(process.env.RPC_URL); // e.g. https://bsc-testnet.publicnode.com	
const chainEnv: ChainEnviroment = 'testnet';
const didRegistry = new DidRegistry(provider, address, {chainEnvironment: chainEnv});
// ... use didRegistry client
const randomDid = DidIdentifier.create(
  Wallet.createRandom().address,
  didRegistry.getDid().chainEnviroment
);
didRegistry.resolve(randomDid)
    .then((didDocument) => {
        console.log(didDocument);
    })
    .catch((error) => {
        console.log(error);
    });
```

#### Via Wallet
```typescript
    const address = "0x88a05b4370BbB90c9F3EEa72A65c77131a7bc18d";
    const provider = getDefaultProvider(process.env.RPC_URL); // e.g. https://bsc-testnet.publicnode.com	
    const randomWallet = Wallet.createRandom().connect(provider);
    const chainEnv: ChainEnviroment = 'testnet';
    const didRegistry = new DidRegistry(randomWallet, address, {chainEnvironment: chainEnv});
    // ... use didRegistry client
    // not passing a DID will resolve the DID of the wallet address
    didRegistry.resolve()
      .then((didDocument) => {
        console.log(didDocument);
      })
      .catch((error) => {
        console.log(error);
      });
```
### DID resolution information
`did:bnb` DIDs are resolved in the following way:
1. `Generative` DIDs are DIDs that have no persisted DID account. (e.g. every valid EOA address is in this state).
   This will return a generative DID document where only the public key of the Account is a valid Verification Method.
2. `Persisted` DIDs are DIDs that have a persisted DID account. Here the DID document represents the state that is found
   on-chain.

### Check generative state (read-only)
```typescript
    // can optionally take a DIDIdentifier as a parameter 
    const isGenerative: boolean = await didRegistry.isGenerativeDidState();
```

### Init a DID on-chain

```typescript
const tx: ContractTransaction = await didRegistry.initializeDidState();
```

### Add a VerificationMethod
This operation adds a new Verification Method to the DID. The `keyData` can be a generically sized `UInt8Array`, but logically it must match the `methodType` specified.

```typescript
const verificationMethod = {
   fragment: 'test',
   flags: reduceVmFlagArray([
      BitwiseVerificationMethodFlag.CapabilityInvocation,
   ]),
   methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod2020,
   keyData: utils.arrayify(Wallet.createRandom().address),
};
const tx: ContractTransaction = await didRegistry.addVerificationMethod(verificationMethod);
```

### Remove a VerificationMethod
This code removes a Verification Method with the given `fragment` from the DID. It is important to keep at least one valid Verification Method with a Capability Invocation flag to prevent a lockout.

```typescript
const tx: ContractTransaction = await didRegistry.removeVerificationMethod('test');
```

### Add a Service
This operation sets a new service on a DID. `serviceType` are strings, not enums, and can therefore be freely defined.

```typescript
   const service = {
      fragment: 'test2',
      service_type: 'testType',
      service_endpoint: 'testEndpoint',
   };
   const tx: ContractTransaction = await didRegistry.addService(service);
```

### Remove a Service
This operation removes a service with the given `fragment` name from the DID.

```typescript
  const tx: ContractTransaction = await didRegistry.removeService('test2');
```

### Set VerificationMethodFlags
This sets/updates the flag on an existing VerificationMethod. **Important** if the flag contains `VerificationMethodFlags.OwnershipProof`
this transaction MUST use the same authority as the Verification Method. (e.g. proving that the owner can sign with
that specific VM).

```typescript
  const tx: ContractTransaction = await didRegistry
        .setVerificationMethodFlags('test', [
           BitwiseVerificationMethodFlag.Authentication,
        ]);
```

### Add Native Controller (did:bnb - DID)
```typescript
   const randomWallet = Wallet.createRandom();
   const nativeController = DidIdentifier.create(
        randomWallet.address,
        didRegistry.getDid().chainEnviroment
   );
   const tx: ContractTransaction = await didRegistry
        .addNativeController(nativeController);
```

### Add External Controller (non-did:bnb DID)
```typescript
  const externalController = `did:sol:testZ3V3Sr5rwjY8573coZnvEKWCifNtnhXedW5YR6m`;

   const tx: ContractTransaction = await didRegistry
           .addExternalController(externalController);
```

## Local Integration Test Setup
This repository uses `test:integration` to run integration test. These test will run against whatever `RPC_URL` is provided in the `.env` file.

To run the integration test navigate to the `ts-client` directory and run `yarn run test:integration`.

### Testing with Foundry
Foundry has a built in testnet node called `anvil`. You can first download foundry by following the [steps here](https://book.getfoundry.sh/getting-started/installation).

Once foundry is installed run the command in a terminal to start the node:

```anvil```

Lastly update the `RPC_URL` variable in your `.env` file to `http://127.0.0.1:8545`.

