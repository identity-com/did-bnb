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

## Other EVM based DID methods (for reference)
- [did:ethr](https://github.com/decentralized-identity/ethr-did-resolver/blob/master/doc/did-method-spec.md)
- [did:jolo](https://github.com/jolocom/jolo-did-method/blob/master/jolocom-did-method-specification.md)
- [did:selfkey](https://github.com/SelfKeyFoundation/selfkey-did-ledger/blob/develop/DIDMethodSpecs.md)
- [did:safe](https://github.com/ceramicnetwork/CIPs/blob/main/CIPs/cip-101.md)
