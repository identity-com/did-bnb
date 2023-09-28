pragma solidity ^0.8.19;

import {DIDRegistry} from "../src/DidRegistry.sol";
import { DidRegistryTest } from "./DidRegistryTest.sol";

contract DidRegistryVerificationMethodTest is DidRegistryTest {

    function test_should_create_new_verification_method() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(0),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        vm.stopPrank(); 

        DIDRegistry.DidState memory finalState = didRegistry.resolveDidState(user);

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

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(0),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        didRegistry.removeVerificationMethod(user, newVm.fragment);

        DIDRegistry.DidState memory finalState = didRegistry.resolveDidState(user);

        assertEq(finalState.verificationMethods.length,1);
    }

    function test_authorized_user_should_remove_verification_method() public {
        address user = vm.addr(1);
        address nonAuthorizedUser = vm.addr(2);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.CAPABILITY_INVOCATION)),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(nonAuthorizedUser)
        });

        vm.startPrank(user); // Send transaction as the authorized user

        _attemptToAddVerificationMethod(user, newVm);

        vm.stopPrank();

        vm.startPrank(nonAuthorizedUser);

        didRegistry.removeVerificationMethod(user, newVm.fragment);

        DIDRegistry.DidState memory finalState = didRegistry.resolveDidState(user);

        assertEq(finalState.verificationMethods.length,1);
    }

    function test_should_update_verification_method_flags() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(0),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        uint16 newFlags = uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.ASSERTION));

        bool result = didRegistry.updateVerificationMethodFlags(user, newVm.fragment, newFlags);
        DIDRegistry.DidState memory finalState = didRegistry.resolveDidState(user);

        assertEq(result, true);
        assertEq(finalState.verificationMethods[1].flags,newFlags);
    }

    function test_revert_only_authorized_keys_can_add_verification_methods() public {
        address user = vm.addr(1);
        address nonAuthorizedUser = vm.addr(2);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'test-fragment',
            flags: uint16(0),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(nonAuthorizedUser)
        });

        vm.startPrank(user);
        didRegistry.initializeDidState(user);
        vm.stopPrank();

        vm.startPrank(nonAuthorizedUser); // Send transaction as the nonAuthorizedUser

        vm.expectRevert("Message sender is not an authorized user of this did");
        didRegistry.addVerificationMethod(user, newVm);
    }

    function test_revert_only_did_authorized_keys_can_remove_verification_methods() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(0),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        vm.stopPrank();

        address nonAuthorizedUser = vm.addr(2);
        vm.startPrank(nonAuthorizedUser); // Send transaction as the nonAuthorizedUser

        vm.expectRevert("Message sender is not an authorized user of this did");
        didRegistry.removeVerificationMethod(user, newVm.fragment);
    }

    function test__revert_should_not_update_verification_method_to_prevent_lockout() public {
        address user = vm.addr(1);

        vm.startPrank(user); // Send transaction as the user

        didRegistry.initializeDidState(user);

        vm.expectRevert("Cannot remove last authority verification method");
        didRegistry.updateVerificationMethodFlags(user, 'default', uint16(uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.DID_DOC_HIDDEN)));
    }

    function test__revert_should_not_allow_adding_unknown_flag_to_verification_method() public {
        address user = vm.addr(1);

        vm.startPrank(user); // Send transaction as the user

        didRegistry.initializeDidState(user);
        DIDRegistry.DidState memory didState = didRegistry.resolveDidState(user);
        
        DIDRegistry.VerificationMethod memory defaultVerificationMethod = didState.verificationMethods[0];

        // Add none supported flag
        uint16 newFlags = defaultVerificationMethod.flags & uint16(uint16(1) << uint16(type(DIDRegistry.VerificationMethodFlagBitMask).max) + 1);

        vm.expectRevert("Attempted to add unsupported flag");
        didRegistry.updateVerificationMethodFlags(user, defaultVerificationMethod.fragment, newFlags);
    }


    function test_revert_only_authorized_key_can_remove_ownership_proof_flag_on_verification_method() public {
        address userOne = vm.addr(1);
        address userTwo = vm.addr(2);

        vm.startPrank(userTwo); // Send transaction as the userTwo

        // Add a verification method for userOne on userTwo's didState
        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.CAPABILITY_INVOCATION),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(userOne) 
        });

        _attemptToAddVerificationMethod(userTwo, newVm);

        vm.stopPrank();

        vm.startPrank(userOne); // Send transaction as the userOne

        // Remove ownership flag from default as userOne on userTwo's didState
        uint16 newFlags = uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.PROTECTED) | uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.CAPABILITY_INVOCATION);

        vm.expectRevert("Only the verification method authority key can set the ownership proof or protected flags");

        didRegistry.updateVerificationMethodFlags(userTwo, 'default', newFlags);
    }

    function test_revert_only_authorized_key_can_add_ownership_proof_flag_on_verification_method() public {
        address userOne = vm.addr(1);
        address userTwo = vm.addr(2);

        vm.startPrank(userTwo); // Send transaction as the userTwo

        // Add a verification method for userOne on userTwo's didState
        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.CAPABILITY_INVOCATION),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(userOne) 
        });

        _attemptToAddVerificationMethod(userTwo, newVm);

        // Attempt to add ownership flag to new vm as userTwo
        uint16 newFlags = uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.OWNERSHIP_PROOF);

        vm.expectRevert("Only the verification method authority key can set the ownership proof or protected flags");

        didRegistry.updateVerificationMethodFlags(userTwo, newVm.fragment, newFlags);
    }

    function test_revert_only_authorized_key_can_remove_protected_flag_on_verification_methods() public {
        address userOne = vm.addr(1);
        address userTwo = vm.addr(2);

        vm.startPrank(userTwo); // Send transaction as the userTwo

        // Add a verification method for userOne on userTwo's didState
        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.CAPABILITY_INVOCATION),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(userOne) 
        });

        _attemptToAddVerificationMethod(userTwo, newVm);

        vm.stopPrank();

        vm.startPrank(userOne); // Send transaction as the userOne

        // Remove protected flag from default as userOne on userTwo's didState
        uint16 newFlags = uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.CAPABILITY_INVOCATION);

        vm.expectRevert("Only the verification method authority key can set the ownership proof or protected flags");

        didRegistry.updateVerificationMethodFlags(userTwo, 'default', newFlags);
    }

    function test_revert_only_authorized_key_can_add_protected_flag_on_verification_methods() public {
        address userOne = vm.addr(1);
        address userTwo = vm.addr(2);

        vm.startPrank(userTwo); // Send transaction as the userTwo

        // Add a verification method for userOne on userTwo's didState
        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.CAPABILITY_INVOCATION),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(userOne) 
        });

        _attemptToAddVerificationMethod(userTwo, newVm);


        // Attempt to add ownership_proof flag to new verification method as userTwo
        uint16 newFlags = uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.PROTECTED);

        vm.expectRevert("Only the verification method authority key can set the ownership proof or protected flags");

        didRegistry.updateVerificationMethodFlags(userTwo, newVm.fragment, newFlags);
    }

    function test_revert_should_not_be_able_to_remove_verification_method_that_does_not_exist() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(0),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        // Do not add verification method

        vm.startPrank(user); // Send transaction as the user

        didRegistry.initializeDidState(user);
        didRegistry.addVerificationMethod(user, newVm);

        vm.expectRevert("Fragment does not match any verification methods with this did");
        didRegistry.removeVerificationMethod(user, "non-existant-fragment");
    }

    function test_revert_should_not_be_able_to_remove_verification_method_with_protected_flag() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(0),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);
        // attempt to remove the default protected verification method

        vm.expectRevert("Cannot remove verification method because of protected flag");
        didRegistry.removeVerificationMethod(user, 'default');
    }

    function test_revert__should_not_be_able_to_remove_verification_method_if_there_is_only_one() public {
        address user = vm.addr(1);

        vm.startPrank(user); // Send transaction as the user

        didRegistry.initializeDidState(user);

        vm.expectRevert("Cannot remove verification method. Did must always have at least 1 verification method");
        didRegistry.removeVerificationMethod(user, 'any');
    }

    function test_revert_should_not_be_able_to_create_duplicate_verification_methods() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'default', // Should fail because this fragment matchs the same name as the default verification method
            flags: uint16(0),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        didRegistry.initializeDidState(user);

        vm.expectRevert("Fragment already exist");
        didRegistry.addVerificationMethod(user, newVm);
    }
    
    function test_revert_should_not_be_able_to_verification_methods_with_ownership_flag() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'test-fragment',
            flags: uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.OWNERSHIP_PROOF),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        didRegistry.initializeDidState(user);

        vm.expectRevert("Cannot add verification method with ownership_proof or protected flags");
        didRegistry.addVerificationMethod(user, newVm);
    }

    function test_revert_should_not_be_able_to_verification_methods_with_protected_flag() public {
        address user = vm.addr(1);

        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'test-fragment',
            flags: uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.PROTECTED),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        didRegistry.initializeDidState(user);

        vm.expectRevert("Cannot add verification method with ownership_proof or protected flags");
        didRegistry.addVerificationMethod(user, newVm);
    }

    function test_revert_only_authorized_keys_should_be_able_to_update_verification_method_flags() public {
        address user = vm.addr(1);
        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(0),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user

        _attemptToAddVerificationMethod(user, newVm);

        vm.stopPrank();

        address nonAuthorizedUser = vm.addr(2);
        vm.startPrank(nonAuthorizedUser); // Send transaction as the nonAuthorizedUser

        uint16 newFlags = uint16(0);

        vm.expectRevert("Message sender is not an authorized user of this did");
        didRegistry.updateVerificationMethodFlags(user, newVm.fragment, newFlags);
    }

    function test_revert_should_not_be_able_to_update_verification_method_flags_if_vm_does_not_exist() public {
        address user = vm.addr(1);
        DIDRegistry.VerificationMethod memory newVm = DIDRegistry.VerificationMethod({
            fragment: 'verification-new-1',
            flags: uint16(0),
            methodType: DIDRegistry.VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(user)
        });

        vm.startPrank(user); // Send transaction as the user
        didRegistry.initializeDidState(user);

        uint16 newFlags = uint16(0);

        vm.expectRevert("Fragment does not match any verification methods with this did");
        didRegistry.updateVerificationMethodFlags(user, newVm.fragment, newFlags);
    }

}