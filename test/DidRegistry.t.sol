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

    //////// Test for did creation //////////

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

    //////// Test for did updates //////////

    function test_should_create_new_verification_method() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.NONE)),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        vm.stopPrank(); 

        DIDRegistry.DidState memory finalState = didRegistry.resolveDidState(didId);

        // Verify length of vm's
        assertEq(finalState.verificationMethods.length,2);

        // Verify data is added correctly
        DIDRegistry.VerificationMethod memory loadedVm = finalState.verificationMethods[1];

        assertEq(loadedVm.fragment, newVm.fragment);
        assertEq(loadedVm.keyData, newVm.keyData);
        assertEq(uint(loadedVm.methodType), uint(newVm.methodType));
        assertEq(loadedVm.flags, newVm.flags);
    }

    function test_should_remove_verification_method() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.NONE)),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        didRegistry.removeVerificationMethod(didId, newVm.fragment);

        DIDRegistry.DidState memory finalState = didRegistry.resolveDidState(didId);

        assertEq(finalState.verificationMethods.length,1);
    }

    function test_should_update_verification_method_flags() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.NONE)),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        uint16 newFlags = uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.NONE));

        bool result = didRegistry.updateVerificationMethodFlags(didId, newVm.fragment, newFlags);
        DIDRegistry.DidState memory finalState = didRegistry.resolveDidState(didId);

        assertEq(result, true);
        assertEq(finalState.verificationMethods[1].flags,newFlags);
    }

    function testFail_only_did_owner_can_add_verification_methods() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'test-fragment',
            flags: uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.NONE)),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        address nonAuthorizedUser = vm.addr(2);

        vm.startPrank(nonAuthorizedUser); // Send transaction as the nonAuthorizedUser
        _attemptToAddVerificationMethod(user, newVm);
    }

    function testFail_only_did_owner_can_remove_verification_methods() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.NONE)),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        vm.stopPrank();

        address nonAuthorizedUser = vm.addr(2);
        vm.startPrank(nonAuthorizedUser); // Send transaction as the nonAuthorizedUser

        didRegistry.removeVerificationMethod(didId, newVm.fragment);
    }

    function testFail_should_not_be_able_to_remove_verification_method_that_does_not_exist() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.NONE)),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        // Do not add verification method

       vm.startPrank(user); // Send transaction as the user

        didRegistry.removeVerificationMethod(didId, newVm.fragment);
    }

    function testFail_should_not_be_able_to_remove_verification_method_with_protected_flag() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.PROTECTED)),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        didRegistry.removeVerificationMethod(didId, newVm.fragment);
    }

    function testFail_should_not_be_able_to_remove_verification_method_if_there_is_only_one() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        vm.startPrank(user); // Send transaction as the user

        didRegistry.removeVerificationMethod(didId, 'verification-default');
    }

    function testFail_should_not_be_able_to_create_duplicate_verification_methods() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-default', // Should fail because this fragment matchs the same name as the default verification method
            flags: uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.NONE)),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);
    }
    
    function testFail_should_not_be_able_to_verification_methods_with_ownership_and_protected_flags() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'test-fragment',
            flags: uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.PROTECTED),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);
    }

    function testFail_only_owner_should_be_able_to_update_verification_method_flags() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.NONE)),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        vm.stopPrank();

        address nonAuthorizedUser = vm.addr(2);
        vm.startPrank(nonAuthorizedUser); // Send transaction as the nonAuthorizedUser

        uint16 newFlags = uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.NONE));

        bool result = didRegistry.updateVerificationMethodFlags(didId, newVm.fragment, newFlags);
    }

    // function testFail_only_did_owner_can_add_services() public {
        
    // }

    // function testFail_only_did_owner_can_add_native_controllers() public {
        
    // }

    // function testFail_only_did_owner_can_add_external_controllers() public {
        
    // }

    // function testFail_only_did_owner_can_remove_services() public {
        
    // }

    // function testFail_only_did_owner_can_remove_native_controllers() public {
        
    // }

    // function testFail_only_did_owner_can_remove_external_controllers() public {
        
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
 */
