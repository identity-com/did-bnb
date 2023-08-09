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

    //////// Test for did creation and resolution//////////

    function test_should_resolve_did() public {
        address user = vm.addr(1);
        string memory userAsString = "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf"; // foundry vm.addr(1) is deterministic
        string memory did = didRegistry.resolveDid(user);

        assertEq(did, string(abi.encodePacked("did:bnb:", bytes(userAsString))));
    }

    function test_fuzz_should_resolve_did_state(address user) public {
        vm.assume(user > address(0));
        string memory did = didRegistry.resolveDid(user);

        DIDRegistry.DidState memory defaultState = didRegistry.resolveDidState(did);

        //Default the didState should be protected and have an ownership proof and is protected
        assertEq(
            defaultState.verificationMethods[0].flags, 
            uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.PROTECTED)
        );
        assertEq(defaultState.verificationMethods[0].fragment,"verification-default");
        
        // Verify the key on the default verification method matches the address in the did
        assertEq(address(bytes20(defaultState.verificationMethods[0].keyData)), user);
    }

    function test_should_initialize_did_state() public {
        address user = vm.addr(3);
        string memory did = didRegistry.resolveDid(user);

        assertEq(didRegistry.isGenerativeDidState(did), true);

        didRegistry.initializeDidState(did);

        assertEq(didRegistry.isGenerativeDidState(did), false);
    }

    function testFail_should_fail_to_initialize_didState_that_exist() public {
        address user = vm.addr(3);
        string memory did = didRegistry.resolveDid(user);

        // Initialize
        didRegistry.initializeDidState(did);
        // Try to initialize an existing didState
        didRegistry.initializeDidState(did);
    }


    // function testFail_only_did_owner_can_add_services() public {
        
    // }


    // function testFail_only_did_owner_can_remove_services() public {
        
    // }

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
