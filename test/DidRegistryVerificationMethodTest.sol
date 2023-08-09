pragma solidity ^0.8.19;

import {DIDRegistry} from "../src/DidRegistry.sol";
import { DidRegistryTest } from "./DidRegistryTest.sol";

contract DidRegistryVerificationTest is DidRegistryTest {

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

}