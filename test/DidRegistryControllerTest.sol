pragma solidity ^0.8.19;

import {DIDRegistry} from "../src/DidRegistry.sol";
import { DidRegistryTest } from "./DidRegistryTest.sol";

contract DidRegistryControllerTest is DidRegistryTest {
    function test_should_add_new_native_controller() public {
        address user = vm.addr(1);
        address newController = vm.addr(2);

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);

        didRegistry.addNativeController(user, newController);

        address[] memory controllers = didRegistry.resolveDidState(user).nativeControllers;
        assertEq(controllers.length, 1);
        assertEq(controllers[0], newController);
    }

    function test_should_remove_new_native_controller() public {
        address user = vm.addr(1);
        address newController = vm.addr(2);

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);

        didRegistry.addNativeController(user, newController);

        didRegistry.removeNativeController(user, newController);

        address[] memory controllers = didRegistry.resolveDidState(user).nativeControllers;
        assertEq(controllers.length, 0);
    }

    function test_should_add_new_external_controller() public {
        address user = vm.addr(1);
        string memory newController = "did:testExternalController";

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);

        didRegistry.addExternalController(user, newController);

        string[] memory controllers = didRegistry.resolveDidState(user).externalControllers;
        assertEq(controllers.length, 1);
        assertEq(controllers[0], newController);
    }

    function test_should_remove_new_external_controller() public {
        address user = vm.addr(1);
        string memory newController = "did:testExternalController";

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);

        didRegistry.addExternalController(user, newController);

        didRegistry.removeExternalController(user, newController);

        string[] memory controllers = didRegistry.resolveDidState(user).externalControllers;
        assertEq(controllers.length, 0);
    }

    function test_revert_should_fail_to_add_new_external_controller() public {
        address user = vm.addr(1);
        string memory newController = "testExternalController";

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);

        vm.expectRevert("Invalid prefix for external controller. External controls must start with did:");
        didRegistry.addExternalController(user, newController);
    }

    function test_revert_should_fail_to_add_duplicate_native_controller() public {
        address user = vm.addr(1);
        address newController = vm.addr(2);

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);

        didRegistry.addNativeController(user, newController);

        vm.expectRevert("Native controller already exist");
        didRegistry.addNativeController(user, newController);
    }

    function test_revert_should_fail_to_remove_didIdentifier_from_native_controllers() public {
        address user = vm.addr(1);

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);

        didRegistry.addNativeController(user, user);

        vm.expectRevert("Cannot remove default authority key");
        didRegistry.removeNativeController(user, user);
    }

    function test_revert_should_fail_to_remove_controller_that_is_not_a_native_controllers() public {
        address user = vm.addr(1);
        address notController = vm.addr(2);

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);


        vm.expectRevert("Native controller does not exist");
        didRegistry.removeNativeController(user, notController);
    }

    function test_revert_should_fail_to_add_duplicate_external_controller() public {
        address user = vm.addr(1);
        string memory newController = "did:testExternalController";

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);

        didRegistry.addExternalController(user, newController);

        vm.expectRevert("External controller already exist");
        didRegistry.addExternalController(user, newController);
    }

    function test_revert_should_fail_to_remove_controller_that_is_not_an_external_controllers() public {
        address user = vm.addr(1);
        string memory newController = "testExternalController";

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);


        vm.expectRevert("External controller does not exist");
        didRegistry.removeExternalController(user, newController);
    }

    function test_revert_should_fail_only_autorized_keys_can_add_native_controllers() public {
        address user = vm.addr(1);
        address newController = vm.addr(2);

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);

        vm.stopPrank();

        vm.startPrank(newController);

        vm.expectRevert("Message sender is not an authorized user of this did");
        didRegistry.addNativeController(user, newController);
    }

    function test_revert_should_fail_to_only_non_generative_didStates_can_add_native_controllers() public {
        address user = vm.addr(1);
        address newController = vm.addr(2);

        vm.startPrank(user); // Make transactions using users EOA

        vm.expectRevert("Only non-generative didStates are allowed for this call");
        didRegistry.addNativeController(user, newController);
    }

    function test_revert_should_fail_to_only_autorized_keys_can_add_external_controllers() public {
        address user = vm.addr(1);
        string memory newController = "testController";

        address userTriggeringTransaction = vm.addr(2);

        vm.startPrank(user); // Make transactions using users EOA
        didRegistry.initializeDidState(user);

        vm.stopPrank();

        vm.startPrank(userTriggeringTransaction);

        vm.expectRevert("Message sender is not an authorized user of this did");
        didRegistry.addExternalController(user, newController);
    }

    function test_revert_should_fail_to_only_non_generative_didStates_can_add_external_controllers() public {
        address user = vm.addr(1);
        string memory newController = "testController";

        vm.startPrank(user); // Make transactions using users EOA

        vm.expectRevert("Only non-generative didStates are allowed for this call");
        didRegistry.addExternalController(user, newController);
    }
}