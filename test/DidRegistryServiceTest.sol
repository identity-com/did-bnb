pragma solidity ^0.8.19;

import {DIDRegistry} from "../src/DidRegistry.sol";
import { DidRegistryTest } from "./DidRegistryTest.sol";

contract DidRegistryServiceTest is DidRegistryTest {

    function test_should_add_service() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        vm.startPrank(user);

        didRegistry.initializeDidState(didId);

        DIDRegistry.Service memory service = DIDRegistry.Service("test-fragment","testType","testEndpoint");
        didRegistry.addService(didId, service);

        DIDRegistry.DidState memory finalState = didRegistry.resolveDidState(didId);

        assertEq(finalState.services.length, 1);
        assertEq(finalState.services[0].fragment, service.fragment);
        assertEq(finalState.services[0].service_endpoint, service.service_endpoint);
        assertEq(finalState.services[0].service_type, service.service_type);
    }

    function test_should_remove_service() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        vm.startPrank(user);

        didRegistry.initializeDidState(didId);

        DIDRegistry.Service memory service = DIDRegistry.Service("test-fragment","testType","testEndpoint");
        didRegistry.addService(didId, service);

        didRegistry.removeService(didId, service.fragment);

        DIDRegistry.DidState memory finalState = didRegistry.resolveDidState(didId);
        assertEq(finalState.services.length, 0);
    }

    function test_Revert_if_non_authorized_user_attempts_to_add_a_service() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        vm.startPrank(user);
        didRegistry.initializeDidState(didId);
        vm.stopPrank();

        vm.startPrank(vm.addr(2));
        DIDRegistry.Service memory service = DIDRegistry.Service("test-fragment","testType","testEndpoint");

        vm.expectRevert(bytes("Message sender is not the owner of this did"));
        didRegistry.addService(didId, service);
        
    }

    function test_Revert_if_did_is_generative() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        // did is still generative

        DIDRegistry.Service memory service = DIDRegistry.Service("test-fragment","testType","testEndpoint");
        
        vm.startPrank(user);
        vm.expectRevert(bytes("Only non-generative didStates are allowed for this call"));
        didRegistry.addService(didId, service);
        
    }

    function test_Revert_if_adding_service_fragment_that_already_exist() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        vm.startPrank(user);

        didRegistry.initializeDidState(didId);

        DIDRegistry.Service memory service = DIDRegistry.Service("test-fragment","testType","testEndpoint");
        didRegistry.addService(didId, service);

        vm.expectRevert(bytes("Fragment already exist on another service"));
        didRegistry.addService(didId, service);
    }

    function test_Revert_if_non_authorized_user_attempts_to_remove_a_service() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        vm.startPrank(user);

        didRegistry.initializeDidState(didId);

        DIDRegistry.Service memory service = DIDRegistry.Service("test-fragment","testType","testEndpoint");
        didRegistry.addService(didId, service);

        vm.stopPrank();

        vm.startPrank(vm.addr(2));
        vm.expectRevert(bytes("Message sender is not the owner of this did"));
        didRegistry.removeService(didId, service.fragment);
    }
    function test_Revert_if_attempting_to_remove_a_service_that_does_not_exist() public {
        address user = vm.addr(1);
        string memory didId = didRegistry.resolveDid(user);

        vm.startPrank(user);

        didRegistry.initializeDidState(didId);

        vm.expectRevert(bytes("Fragment not found"));
        didRegistry.removeService(didId, "non-existing-fragment");
    }
}