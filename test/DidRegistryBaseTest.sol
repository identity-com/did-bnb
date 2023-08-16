pragma solidity ^0.8.19;

import {DIDRegistry} from "../src/DidRegistry.sol";
import { DidRegistryTest } from "./DidRegistryTest.sol";

contract DidRegistryBaseTest is DidRegistryTest {

    //////// Test for did creation and resolution//////////
    function test_fuzz_should_resolve_did_state(address user) public {
        vm.assume(user > address(0));

        DIDRegistry.DidState memory defaultState = didRegistry.resolveDidState(user);

        //Default the didState should be Invocation and have an ownership proof
        assertEq(
            defaultState.verificationMethods[0].flags, 
            uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.CAPABILITY_INVOCATION)
        );
        assertEq(defaultState.verificationMethods[0].fragment,"default");
        
        // Verify the key on the default verification method matches the address in the did
        assertEq(address(bytes20(defaultState.verificationMethods[0].keyData)), user);
    }

    function test_should_initialize_did_state() public {
        address user = vm.addr(3);

        assertEq(didRegistry.isGenerativeDidState(user), true);

        didRegistry.initializeDidState(user);

        assertEq(didRegistry.isGenerativeDidState(user), false);
    }

    function test_revert_should_fail_to_initialize_didState_that_exist() public {
        address user = vm.addr(3);

        // Initialize
        didRegistry.initializeDidState(user);
        // Try to initialize an existing didState
        vm.expectRevert("Did state already exist");
        didRegistry.initializeDidState(user);
    }
}