// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {DIDRegistry} from "../src/DidRegistry.sol";
import "solidity-stringutils/strings.sol";

contract DidRegistryTest is Test {
    using strings for *;

    DIDRegistry public didRegistry;

    function setUp() public {
        didRegistry = new DIDRegistry();
    }

    function _attemptToAddVerificationMethod(address user, DIDRegistry.VerificationMethod memory newVm) internal  {
        string memory didId = didRegistry.resolveDid(user);
        didRegistry.initializeDidState(didId);
        didRegistry.addVerificationMethod(didId, newVm);
    }
}

/**
Invariants of the system:
- a didState should always have at least 1 verification method
- a verification method that is protected can not be removed
- a verification with an ownership flag can only be edited by the owner of the vm? Need clarity
- only the did owner can add verification methods


Questions:
1) What does the ownership flag do exactly?
2) Can any of the controllers update verification methods?
3) What can the other authority keys update?
4) What does the protected flag mean and when updating verification flags what are the conditions? In the rust contract it is `has_authority_verification_methods`
5) What flags can a user update on their verificationFlags that they own (ie they own the address in keyData)
6) Are controller explicitly added or are they derived from verification methods?
 */
