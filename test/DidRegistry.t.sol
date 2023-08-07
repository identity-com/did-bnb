// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {DIDRegistry} from "../src/DidRegistry.sol";
import "solidity-stringutils/strings.sol";

contract CounterTest is Test {
    using strings for *;

    DIDRegistry public didRegistry;

    function setUp() public {
        didRegistry = new DIDRegistry();
    }

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
}
