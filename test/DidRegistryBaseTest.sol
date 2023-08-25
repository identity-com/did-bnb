pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {DIDRegistry} from "../src/DidRegistry.sol";
import { TestProxy } from "./TestProxy.sol";
import { DidRegistryTest } from "./DidRegistryTest.sol";

contract DIDRegistryTest is Test {

    DIDRegistry public didRegistry;
    TestProxy private proxy;
    DIDRegistry public wrappedProxy;

    function setUp() public {
        didRegistry = new DIDRegistry();
        proxy = new TestProxy(address(didRegistry),"");
        wrappedProxy = DIDRegistry(address(proxy));
    }


    function test_should_initialize_proxy_implementation() public {
        wrappedProxy.initialize();
        assertEq(wrappedProxy.owner(), address(this));
    }

    function test_should_upgrade_proxy_implementation() public {
        // Initialize proxy and add some data
        wrappedProxy.initialize();

        address user = vm.addr(1);
        wrappedProxy.initializeDidState(user);


        assertEq(wrappedProxy.isGenerativeDidState(user), false);

        // Create new implementation and upgrade proxy
        DIDRegistry upgradedRegistry = new DIDRegistry();

        wrappedProxy.upgradeTo(address(upgradedRegistry));

        // The initializedDid should still be non-generative after the upgrade
        assertEq(wrappedProxy.isGenerativeDidState(user), false);
    }

    function test_should_transfer_contract_ownership_to_new_admin() public {
        address newOwner = vm.addr(1);
        wrappedProxy.initialize();

        wrappedProxy.transferOwnership(newOwner);
        assertEq(wrappedProxy.owner(), newOwner);
    }
    

    function test_fuzz_should_resolve_did_state(address user) public {
        vm.assume(user > address(0));

        DIDRegistry.DidState memory defaultState = didRegistry.resolveDidState(user);

        //Default the didState should be Invocation and have an ownership proof
        assertEq(
            defaultState.verificationMethods[0].flags, 
            uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.CAPABILITY_INVOCATION) | uint16(1) << uint16(DIDRegistry.VerificationMethodFlagBitMask.PROTECTED)
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

    function test_should_revert_when_trying_to_initialize_proxy_implementation_twice() public {
        wrappedProxy.initialize();
        vm.expectRevert("Initializable: contract is already initialized");
        wrappedProxy.initialize();
    }

    function test_should_revert_when_nonOwner_tries_to_upgrade_proxy_implementation() public {
        wrappedProxy.initialize();

        address user = vm.addr(1);

        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        wrappedProxy.transferOwnership(user);
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