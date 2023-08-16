// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {DIDRegistry} from "../src/DidRegistry.sol";

contract CounterTest is Test {

    DIDRegistry public didRegistry;

    function setUp() public {
        didRegistry = new DIDRegistry();
    }


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

    function testFail_should_fail_to_initialize_did_that_exist() public {
        address user = vm.addr(3);

        // Initialize
        didRegistry.initializeDidState(user);
        // Try to initialize an existing didState
        didRegistry.initializeDidState(user);
    }
}
